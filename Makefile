path=$(shell pwd)
SERVERURL=`cat serverurl 2>/dev/null | echo "http://127.0.0.1:32773"`
TESTS=$(wildcard $(path)/server/tests/*.js)

dummy:

# run all tests
test: test-server test-client

# run server tests
test-server: dummy
	@touch $(path)/server/config.local.php
	@mv -f $(path)/server/config.local.php $(path)/server/config.local.php.tmp
	@cp -f $(path)/server/tests/config.local.php $(path)/server/config.local.php
	@rm -rf server/data/*
	@vows $(TESTS) --spec
	@mv -f $(path)/server/config.local.php.tmp $(path)/server/config.local.php

# run client tests
test-client: dummy
	@./phantomjs/bin/phantomjs ./phantomjs/examples/run-qunit.js $(SERVERURL)/client/tests/test1.html

setup: dummy
	@cd $(path)/server/lib/ && curl -L https://nodeload.github.com/codeguy/Slim/tarball/1.6.5 > slim.tar.gz && pwd && tar -ztf slim.tar.gz 2>/dev/null | head -1 > /tmp/slimname
	@cd $(path)/server/lib/ && tar xzf slim.tar.gz
	@rm -rf $(path)/server/lib/Slim && mv $(path)/server/lib/`cat /tmp/slimname` $(path)/server/lib/Slim
	@rm -rf $(path)/server/lib/Slim/tests ; rm -rf $(path)/server/lib/Slim/docs
	@rm -f /tmp/slimname && rm -f $(path)/server/lib/slim.tar.gz

# install needed packages for tests run
setup-server-test:
	@cd $(path)/server/tests && npm install vows request async && npm install -g vows

setup-client-test:
	@cd $(path) && wget http://phantomjs.googlecode.com/files/phantomjs-1.6.1-linux-x86_64-dynamic.tar.bz2
	@tar xzf phantomjs-1.6.1-linux-x86_64-dynamic.tar.bz2

setup-minify:
	@npm install -g less clean-css pack

# compress javascript and css
minify: $(path)/client/jquery.phpfreechat.js $(path)/client/themes/default/jquery.phpfreechat.less $(path)/client/themes/default/jquery.phpfreechat.variables.less $(path)/client/themes/default/jquery.phpfreechat.notabs.less
	@cat $(path)/client/jquery.phpfreechat.js $(path)/client/jquery.phpfreechat.*.js | packnode > $(path)/client/jquery.phpfreechat.min.js
	@lessc $(path)/client/themes/default/jquery.phpfreechat.less $(path)/client/themes/default/jquery.phpfreechat.css
	@cleancss $(path)/client/themes/default/jquery.phpfreechat.css > $(path)/client/themes/default/jquery.phpfreechat.min.css 

setup-jshint:
	@npm install -g jshint

jshint:
	@jshint $(wildcard $(path)/client/*.js) $(wildcard $(path)/server/tests/*.js)

phpcs:
	@phpcs --standard=Zend --tab-width=2  --encoding=utf-8 --sniffs=Generic.Functions.FunctionCallArgumentSpacing,Generic.Functions.OpeningFunctionBraceBsdAllmann,Generic.PHP.DisallowShortOpenTag,Generic.WhiteSpace.DisallowTabIndent,PEAR.ControlStructures.ControlSignature,PEAR.Functions.ValidDefaultValue,PEAR.WhiteSpace.ScopeClosingBrace,Generic.Files.LineEndings -s $(wildcard $(path)/server/*.php) $(wildcard $(path)/server/routes/*.php) $(wildcard $(path)/server/container/*.php)

clean: dummy
	@rm -f $(path)/client/*.min.js
	@rm -f $(path)/client/themes/default/jquery.phpfreechat.css
	@rm -f $(path)/client/themes/default/jquery.phpfreechat.min.css
	@rm -rf $(path)/server/data/*
	@rm -f $(path)/server/logs/*

clean-release: setup setup-minify minify
	@rm -f $(path)/client/lib/less-*.js
	@rm -rf $(path)/client/tests
	@rm -rf $(path)/server/tests
	@rm -rf $(path)/server/data/*
	@rm -f $(path)/server/logs/*
	@rm -f $(path)/Makefile
	@rm -f $(path)/.jshintrc
	@rm -f $(path)/.jshintignore
	@rm -rf $(path)/.git

clean-release-for-dev: clean-release
	@rm -f $(path)/client/*.min.js
	@cat $(path)/client/*.js > $(path)/client/jquery.phpfreechat.js.tmp
	@rm -f $(path)/client/*.js
	@mv $(path)/client/jquery.phpfreechat.js.tmp $(path)/client/jquery.phpfreechat.js
	@rm -f $(path)/client/themes/default/*.less
	@rm -f $(path)/client/themes/default/jquery.phpfreechat.min.css
	@tools/switch-examples-head --dev
	@rm -rf $(path)/tools

clean-release-for-prod: clean-release
	@mv $(path)/client/jquery.phpfreechat.min.js $(path)/client/jquery.phpfreechat.min.js.tmp
	@rm -f $(path)/client/*.js
	@mv $(path)/client/jquery.phpfreechat.min.js.tmp $(path)/client/jquery.phpfreechat.min.js
	@rm -f $(path)/client/themes/default/*.less
	@mv $(path)/client/themes/default/jquery.phpfreechat.min.css $(path)/client/themes/default/jquery.phpfreechat.min.css.tmp 
	@rm -f $(path)/client/themes/default/*.css
	@mv $(path)/client/themes/default/jquery.phpfreechat.min.css.tmp $(path)/client/themes/default/jquery.phpfreechat.min.css
	@tools/switch-examples-head --prod
	@rm -rf $(path)/tools

release: dummy
	@tools/build-release