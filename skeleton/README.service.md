# spring-boot-template

## Local development

- clone this repository
- run `make setup` to create a local `.env` file
- start the dependencies via `docker compose up`
- launch the application from IntelliJ

## Tests

You can run the tests by using the following command:
```shell
$ make test
```

## Linting

We use ktlint for linting. You can run it by using the following command:
```shell
$ make lint
```

Ktlint is also able to fix a lot of the violations, to do so run the following the command:
```shell
$ make lint-fix
```

Or you can integrate it with your IntelliJ's formatter by running the following commands in the project's root directory:

```shell
$ brew install ktlint

# To enable ktlint only for the current project
$ ktlint applyToIDEAProject

# To enable ktlint for all IDEA projects
$ ktlint applyToIDEA
```

## OpenAPI

We generate and publishes clients via the [openapi-generator](https://www.github.com/Jimdo/openapi-generator).
This happens in the CD pipeline after the production deployment.

### Accessing swagger ui

The service exposes it's OpenAPI documentation via swagger, it can be found at /docs/swagger-ui.html
and is protected via basic auth. The username is `docs`, the password can be found in vault and is `jimdo` for local development.

## Management (Actuator)
On port 8081 of the application we expose the /health and /metrics endpoints.
The first is for our ELB. More info about them in the Spring Boot Actuator Docs.
Do note that the port is not available to the internet when deployed to the wonderland.

## OpenTelemetry
The service reports traces to our open telemetry collectors from staging and production.
In the local setup it is not enabled.
