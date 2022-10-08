.PHONY: build
.PHONY: test
.PHONY: clean

build:
	dub build --build=release

build-docs:
	dub build --build=ddox

test:
	dub test

clean:
	dub clean	

run-examples: run-annotationsExample \
	run-applicationContextExample \
	run-arrayCompletionExample \
	run-constructorInjectionExample \
	run-injectionInitializerExample \
	run-postConstructorPreDestructorExample \
	run-qualifiersExample \
	run-quickstartExample \
	run-registerOnResolveExample \
	run-valueInjectionExample

run-annotationsExample:
	dub run --build=release --config=annotationsExample

run-applicationContextExample:
	dub run --build=release --config=applicationContextExample

run-arrayCompletionExample:
	dub run --build=release --config=arrayCompletionExample

run-constructorInjectionExample:
	dub run --build=release --config=constructorInjectionExample

run-injectionInitializerExample:
	dub run --build=release --config=injectionInitializerExample

run-postConstructorPreDestructorExample:
	dub run --build=release --config=postConstructorPreDestructorExample

run-qualifiersExample:
	dub run --build=release --config=qualifiersExample

run-quickstartExample:
	dub run --build=release --config=quickstartExample

run-registerOnResolveExample:
	dub run --build=release --config=registerOnResolveExample

run-valueInjectionExample:
	dub run --build=release --config=valueInjectionExample