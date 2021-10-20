FROM envoyproxy/envoy:v1.20-latest
COPY ./*.yaml /etc/envoy/
# COPY ./envoy-cluster-read.yaml /etc/envoy/envoy-cluster-read.yaml
RUN chmod go+r /etc/envoy/envoy.yaml
