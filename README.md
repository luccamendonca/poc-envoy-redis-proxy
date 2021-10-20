# PoC - Migrating standalone redis to keydb cluster using envoy's RedisProxy

This is a really simple (and probably flawed in many ways) proof of concept that
aims to find out whether or not it is a good idea using Envoy's RedisProxy to
migrate from a standalone redis instance to a KeyDB cluster.

## Running the environment

Start by running the following command (needs `docker`):

```
make run
```

This command will spin-up an environment containing a standalone Redis instance,
a KeyDB cluster (3 primaries, 3 secondaries) and an Envoy proxy configured with
the RedisProxy filter

The Envoy instance should receive all redis operations, route them to the
standalone Redis instance and replicate the commands to the keydb cluster, while
making sure all the reads happen only on the former.

## Testing some basic operations

The following command will run tests considering the scenario where the reads
are being made on the standalone instance (needs `redis-cli`):

```
make test-envoy-read-from-single
```

## Switching Envoy's read upstream to the keydb cluster

```
make envoy-read-from-cluster
```

This command stops the current envoy container and starts a new one, now using
the keydb cluster as the main upstream, while mirroring the write commands to
the standalone redis.

```diff
 prefix_routes:
     catch_all_route:
-        cluster: standalone_redis
+        cluster: redis_cluster
         request_mirror_policy:
-            cluster: redis_cluster
+            cluster: standalone_redis
             exclude_read_commands: true

```

The following command will run the same tests as before, but this time stopping
the standalone redis container instead of the cluster one, making sure that
