.PHONY: install server watch clean test help
APP_NAME := $(shell basename $(CURDIR))
ELM_FILES = $(shell find src -type f -name '*.elm')
SCSS_FILES = $(shell find styles -type f -name '*.scss')
HTML_FILES = $(shell find pages -type f -name '*.html')
INTEROP_FILES = $(shell find interop -type f -name '*.js')
NODE_BIN_DIRECTORY = node_modules/.bin
DEVD_VERSION = 0.3
WELLINGTON_VERSION = 1.0.2
MODD_VERSION = 0.3
ELM_TEST_VERSION = 0.16
OS := $(shell uname)
INSTALL_TARGETS = src bin build \
									Makefile \
									elm-package.json \
									src/$(call titlecase,$(APP_NAME))/Main.elm styles/$(APP_NAME)/main.scss \
									pages/$(APP_NAME)/index.html interop/$(APP_NAME)/app.js \
									bin/modd modd.conf \
									bin/devd bin/wt \
									.gitignore \
									$(CUSTOM_INSTALL_TARGETS)
TEST_TARGETS = $(NODE_BIN_DIRECTORY)/elm-test test/TestRunner.elm
SERVER_OPTS = -w build -l build/ $(CUSTOM_SERVER_OPTS)
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

ifeq ($(OS),Darwin)
	DEVD_URL = "https://github.com/cortesi/devd/releases/download/v${DEVD_VERSION}/devd-${DEVD_VERSION}-osx64.tgz"
	WELLINGTON_URL = "https://github.com/wellington/wellington/releases/download/v${WELLINGTON_VERSION}/wt_v${WELLINGTON_VERSION}_darwin_amd64.tar.gz"
	MODD_URL = "https://github.com/cortesi/modd/releases/download/v${MODD_VERSION}/modd-${MODD_VERSION}-osx64.tgz"
else
	DEVD_URL = "https://github.com/cortesi/devd/releases/download/v${DEVD_VERSION}/devd-${DEVD_VERSION}-linux64.tgz"
	WELLINGTON_URL = "https://github.com/wellington/wellington/releases/download/v${WELLINGTON_VERSION}/wt_v${WELLINGTON_VERSION}_linux_amd64.tar.gz"
	MODD_URL = "https://github.com/cortesi/modd/releases/download/v${MODD_VERSION}/modd-${MODD_VERSION}-linux64.tgz"
endif

map = $(foreach a,$(2),$(call $(1),$(a)))
split = $(subst $1, ,$2)
head = $(shell echo $1 | head -c 1)
tail = $(shell echo $1 | tail -c +2)
capitalize_path = $(subst $(SPACE),/,$(call map,titlecase,$(call split,/,$1)))
uppercase = $(shell echo $1 | tr a-z A-Z)
titlecase = $(call uppercase,$(call head,$1))$(call tail,$1)

all: $(COMPILE_TARGETS) ## Compiles project files

install: $(INSTALL_TARGETS) ## Installs prerequisites and generates file/folder structure

server: ## Runs a local server for development
	bin/devd $(SERVER_OPTS)

watch: ## Watches files for changes, runs a local dev server and triggers live reload
	bin/modd

clean: ## Removes compiled files
	rm build/*

test: $(TEST_TARGETS) ## Runs unit tests via elm-test
	$(NODE_BIN_DIRECTORY)/elm-test test/TestRunner.elm

help: ## Prints a help guide
	@echo "Available tasks:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build bin src styles pages interop:
	mkdir -p $@

Makefile:
	test -s $@ || echo "$$Makefile" > $@

styles/main.scss: styles
	test -s $@ || touch $@

test/TestRunner.elm:
	$(NODE_BIN_DIRECTORY)/elm-test init --yes
	mkdir -p test
	mv *.elm test/

bin/devd:
	curl ${DEVD_URL} -L -o $@.tgz
	tar -xzf $@.tgz -C bin/ --strip 1
	rm $@.tgz

bin/wt:
	curl ${WELLINGTON_URL} -L -o $@.tgz
	tar -xzf $@.tgz -C bin/
	rm $@.tgz

bin/modd:
	curl ${MODD_URL} -L -o $@.tgz
	tar -xzf $@.tgz -C bin/ --strip 1
	rm $@.tgz

modd.conf:
	echo "$$modd_config" > $@

elm-package.json:
	echo "$$elm_package_json" > $@

node_modules/.bin/elm-test:
	npm install elm-test@${ELM_TEST_VERSION}

.gitignore:
	echo "$$gitignore" > $@

build/%.css: $(SCSS_FILES)
	bin/wt compile -b build/$(dir $*) styles/$*.scss

build/%/interop.js: $(INTEROP_FILES) interop
	mkdir -p build/$*
	cp interop/$*/app.js $@

build/%.js: $(ELM_FILES)
	elm make src/$(call capitalize_path,$*).elm --yes --warn --output $@

build/%.html: $(HTML_FILES) pages
	mkdir -p build/$(dir $*)
	cp pages/$*.html $@

src/$(APP_NAME):
	mkdir -p src/$(call titlecase,$(APP_NAME))

styles/$(APP_NAME) pages/$(APP_NAME) interop/$(APP_NAME):
	mkdir -p $@

src/%.elm: src/$(APP_NAME)
	test -s $@ || echo "$$main_elm" > $@

styles/%.scss: styles/$(APP_NAME)
	touch $@

pages/%.html: pages/$(APP_NAME)
	test -s $@ || echo "$$index_html" > $@

interop/%.js: interop/$(APP_NAME)
	test -s $@ || echo "$$interop_js" > $@

define Makefile
COMPILE_TARGETS := build/$(APP_NAME)/main.js \
									 build/$(APP_NAME)/main.css \
									 build/$(APP_NAME)/index.html \
									 build/$(APP_NAME)/interop.js

include elm.mk
endef
export Makefile

define modd_config
src/**/*.elm interop/**/*.js pages/**/*.html styles/**/*.scss {
  prep: make -j 2
}
build/** {
  daemon: make server
}
endef
export modd_config

define main_elm
module Main exposing (..)

import Html exposing (div, text, Html)
import Html.App as Html
import Platform.Sub as Sub


type Msg
    = NoOp


type alias Model =
    Int


model : Model
model =
    0


view : Model -> Html Msg
view model =
    div []
        [ model |> toString |> text ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program Never
main =
    Html.program
        { init = ( model, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
endef
export main_elm

define elm_package_json
{
    "version": "1.0.0",
    "summary": "helpful summary of your project, less than 80 characters",
    "repository": "https://github.com/user/project.git",
    "license": "BSD3",
    "source-directories": [
        "src",
        "test"
    ],
    "exposed-modules": [],
    "dependencies": {
        "elm-lang/core": "4.0.0 <= v < 5.0.0",
        "elm-lang/html": "1.0.0 <= v < 2.0.0",
        "evancz/elm-http": "3.0.1 <= v < 4.0.0"
    },
    "elm-version": "0.17.0 <= v < 0.18.0"
}
endef
export elm_package_json

define interop_js
window.onload = function() {
  var app = Elm.Main.fullscreen();
};
endef
export interop_js

define index_html
<!DOCTYPE HTML>
<html>
<head>
  <meta charset="UTF-8">
  <title>Elm Project</title>
  <link rel="stylesheet" href="/main.css">
</head>
<body>
</body>
  <script type="text/javascript" src="main.js"></script>
  <script type="text/javascript" src="interop.js"></script>
</html>
endef
export index_html

define gitignore
elm-stuff
elm.js
/build/*
/bin/*
endef
export gitignore
