PACKAGE  := short-execution
DIST_DIR := dist
ZIP      := $(DIST_DIR)/$(PACKAGE).zip
PY       := python3

.PHONY: clean install package deploy

clean:
	rm -rf $(DIST_DIR) .build __pycache__

install:
	pip install -r requirements.txt -t $(DIST_DIR)/deps --upgrade --quiet

package: clean install
	mkdir -p $(DIST_DIR)
	cp handler.py $(DIST_DIR)/
	cd $(DIST_DIR) && cp -r deps/* . && rm -rf deps
	cd $(DIST_DIR) && zip -r9 ../$(ZIP) . -x "*.pyc" -x "__pycache__/*"
	@echo "Package ready: $(ZIP)"

deploy: package
	aws lambda update-function-code \
	  --function-name $${LAMBDA_FUNCTION_NAME} \
	  --zip-file fileb://$(ZIP) \
	  --region $${AWS_REGION:-us-east-1}
