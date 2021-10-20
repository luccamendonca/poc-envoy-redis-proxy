run:
	@docker run --name redis_single -d -p 6379:6379 redis || docker start redis_single
	@docker build -t redis-envoy-proxy .
	@cd keydb-cluster && docker build -t keydb-cluster .
	@KEYDB_CLUSTER_IP=0.0.0.0 docker run --name keydb_cluster -d -p 7000-7010:7000-7010 -p 5000-5010:5000-5010 keydb-cluster
	@${MAKE} envoy-read-from-single

clean:
	@docker ps -a --format "{{.Names}}" | grep -i -E "redis_|keydb_" | xargs docker rm -f

envoy-read-from-cluster:
	@-docker stop redis_envoy_proxy
	@docker run --name redis_envoy_proxy_cluster_read -d -p 1936:1936 -p 9091:9091 redis-envoy-proxy "-c /etc/envoy/envoy-cluster-read.yaml" || docker start redis_envoy_proxy_cluster_read

envoy-read-from-single:
	@-docker stop redis_envoy_proxy_cluster_read
	@docker run --name redis_envoy_proxy -d -p 1936:1936 -p 9091:9091 redis-envoy-proxy || docker start redis_envoy_proxy

base-test:
	@echo; echo ">> Setting keys a=1, b=2 via Envoy Proxy"
	@echo "   [must output OK]"
	@printf "A => "; echo "SET a 1" | redis-cli -p 9091
	@printf "B => "; echo "SET b 2" | redis-cli -p 9091

	@echo; echo ">> Getting keys a, b via Envoy Proxy"
	@echo "   [must read BOTH values]"
	@printf "A => "; echo "GET a" | redis-cli -p 9091
	@printf "B => "; echo "GET b" | redis-cli -p 9091

	@echo; echo ">> Getting keys a, b via redis_single"
	@echo "   [must read BOTH values]"
	@printf "A => "; echo "GET a" | redis-cli -p 6379
	@printf "B => "; echo "GET b" | redis-cli -p 6379

	@echo; echo ">> Getting keys a, b via cluster:7000"
	@echo "   [must read ONE value]"
	@printf "A => "; echo "GET a" | redis-cli -p 7000
	@printf "B => "; echo "GET b" | redis-cli -p 7000

	@echo; echo ">> Getting keys a, b via cluster:7002"
	@echo "   [must read THE OTHER value]"
	@printf "A => "; echo "GET a" | redis-cli -p 7002
	@printf "B => "; echo "GET b" | redis-cli -p 7002

test-envoy-read-from-single:
	@echo "Run this test **before** running 'make envoy-read-from-cluster'"
	@echo ""
	@echo "This test ensures that:"
	@echo "1. Commands issued via Envoy Proxy (:9091) writes to both upstreams (redis_single & *_cluster)"
	@echo "2. Read operations must always happen on redis_single"
	@echo "3. We must be able to read from each specific instance from redis|keydb_cluster using the 7000-7002 ports"

	@${MAKE} base-test

	@echo; echo ">> Stopping keydb_cluster..."
	@docker stop keydb_cluster

	@echo; echo ">> Getting keys a, b via Envoy Proxy"
	@echo "   [must read BOTH values (to ensure reads are made from redis_single)]"
	@printf "A => "; echo "GET a" | redis-cli -p 9091
	@printf "B => "; echo "GET b" | redis-cli -p 9091

	@echo; echo ">> Getting keys a, b via cluster:7000"
	@echo "   [must FAIL]"
	@printf "A => "; echo "GET a" | redis-cli -p 7000
	@printf "B => "; echo "GET b" | redis-cli -p 7000

	@echo; echo ">> Starting keydb_cluster..."
	@docker start keydb_cluster

test-envoy-read-from-cluster:
	@echo "Run this test **after** running make envoy-read-from-cluster."
	@echo ""
	@echo "This test ensures that:"
	@echo "1. Commands issued via Envoy Proxy (:9091) writes to both upstreams (redis_single & *_cluster)"
	@echo "2. Read operations must always happen on redis|keydb_cluster"
	@echo "3. We must be able to read from redis_single using the 6379 port"
	@echo "4. We should be able to take redis_single down without any negative effect to the client"

	@${MAKE} base-test

	@echo; echo ">> Stopping redis_single..."
	@docker stop redis_single

	@echo; echo ">> Getting keys a, b via Envoy Proxy"
	@echo "   [must read BOTH values (to ensure reads are made from redis_single)]"
	@printf "A => "; echo "GET a" | redis-cli -p 9091
	@printf "B => "; echo "GET b" | redis-cli -p 9091

	@echo; echo ">> Getting keys a, b via redis_single:6379"
	@echo "   [must FAIL]"
	@printf "A => "; echo "GET a" | redis-cli -p 6379
	@printf "B => "; echo "GET b" | redis-cli -p 6379

	@echo; echo ">> Starting redis_single..."
	@docker start redis_single
