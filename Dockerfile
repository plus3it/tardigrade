FROM plus3it/tardigrade-ci:0.0.2

WORKDIR /ci-harness
ENTRYPOINT ["make"]

