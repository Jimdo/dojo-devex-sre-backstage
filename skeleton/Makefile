AWS_REGION             = eu-west-1
REGISTRY               = registry.jimdo-platform.net
SERVICE_NAME           = spring-boot-template
IMAGE                  = $(REGISTRY)/jimdo/$(SERVICE_NAME)
TEAM                   = developers
TERRAFORM              = ./terraform
TF_IN_AUTOMATION       = 1
TF_VAR_service_name    = $(SERVICE_NAME)
TF_WORKSPACE           = $(ENV)
VAULT                  = $(TEAM)/$(SERVICE_NAME)-$(ENV)
VERSION                = $(shell git describe --always --dirty)
WL                     = ./wl

export AWS_REGION
export ENV
export IMAGE
export SERVICE_NAME
export TEAM
export TF_VAR_service_name
export TF_WORKSPACE
export TF_IN_AUTOMATION
export VAULT
export VERSION

guard-%:
	@ if [ "${${*}}" = "" ]; then \
	    echo "Environment variable $* not set"; \
	    exit 1; \
	fi

setup: secrets

secrets: $(WL)
	$(WL) vault read $(TEAM)/$(SERVICE_NAME)-local --output=dotenv  > .env

generate-openapi-docs:
	sed -i 's/authorize("\/docs\/\*\*", hasRole(ROLE_DOCS_USER))/authorize("\/docs\/\*\*", permitAll)/' src/main/kotlin/com/jimdo/template/config/SecurityConfig.kt
	./gradlew generateOpenApiDocs
	sed -i 's/authorize("\/docs\/\*\*", permitAll)/authorize("\/docs\/\*\*", hasRole(ROLE_DOCS_USER))/' src/main/kotlin/com/jimdo/template/config/SecurityConfig.kt

verify-docker-image:
	./scripts/verify-docker-image.sh

test:
	./gradlew test

lint:
	./gradlew check -x test

lint-fix:
	./gradlew ktlintFormat

validate-wl-config: $(WL)
	$(WL) validate ./wonderland.yaml

build:
	./gradlew jibDockerBuild --image=$(IMAGE):$(VERSION)

push-without-building: $(WL)
	$(WL) docker push $(IMAGE):$(VERSION)

push: build push-without-building

deploy-without-pushing: $(WL) guard-ENV
	$(WL) deploy $(SERVICE_NAME)-$(ENV) -f ./infrastructure/wonderland.yml

deploy: push deploy-without-pushing guard-ENV

$(WL):
	curl -sSLfo $(WL) https://downloads.jimdo-platform.net/wl/latest/wl_latest_$(shell uname -s | tr A-Z a-z)_$(shell uname -m | sed "s/x86_64/amd64/")
	chmod +x $(WL)

$(TERRAFORM):
	@curl -sSLfo ./terraform.zip "https://releases.hashicorp.com/terraform/1.0.2/terraform_1.0.2_$(shell uname -s|tr A-Z a-z)_amd64.zip"
	@unzip -qq terraform.zip
	@rm -f terraform.zip

infrastructure-plan: guard-ENV guard-AWS_SECRET_ACCESS_KEY guard-AWS_ACCESS_KEY_ID $(TERRAFORM) $(WL)
	cd infrastructure && ../$(TERRAFORM) init -input=false \
	&& ../$(TERRAFORM) plan -input=false

infrastructure-apply: guard-ENV guard-AWS_SECRET_ACCESS_KEY guard-AWS_ACCESS_KEY_ID $(TERRAFORM) $(WL)
	cd infrastructure && ../$(TERRAFORM) init -input=false \
	&& ../$(TERRAFORM) apply -input=false -auto-approve=true \
	&& ../$(WL) vault write $(VAULT) \
			DATABASE_ENDPOINT=`../$(TERRAFORM) output -raw database_endpoint` \
			DATABASE_PORT=`../$(TERRAFORM) output -raw database_port` \
			DATABASE_NAME=`../$(TERRAFORM) output -raw database_name` \
			DATABASE_USER=`../$(TERRAFORM) output -raw database_main_user` \
			DATABASE_PASSWORD=`../$(TERRAFORM) output -raw database_main_password`

.PHONY: setup secrets
.PHONY: test validate-wl-config generate-openapi-docs lint lint-fix
.PHONY: build push push-without-building
.PHONY: deploy-without-pushing deploy
.PHONY: infrastructure-plan infrastructure-apply
