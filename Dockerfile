FROM plus3it/tardigrade-ci:0.0.3

WORKDIR /ci-harness
ENTRYPOINT ["make"]

