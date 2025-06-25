/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2025 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.testclasses;

version (unittest)  :  //

import poodinis;
import poodinis.foreigndependencies;

class ComponentA {
}

class ComponentB {
    @Inject ComponentA componentA;
}

interface InterfaceA {
}

class ComponentC : InterfaceA {
}

class ComponentD {
    @Inject InterfaceA componentC = null;
    private @Inject InterfaceA _privateComponentC = null;

    InterfaceA privateComponentC() {
        return _privateComponentC;
    }
}

class DummyAttribute {
}

class ComponentE {
    @DummyAttribute ComponentC componentC;
}

class ComponentDeclarationCocktail {
    alias noomer = int;

    @Inject ComponentA componentA;

    void doesNothing() {
    }

    ~this() {
    }
}

class ComponentX : InterfaceA {
}

class ComponentZ : ComponentB {
}

class MonkeyShine {
    @Inject!ComponentX InterfaceA component;
}

class BootstrapBootstrap {
    @Inject!ComponentX InterfaceA componentX;

    @Inject!ComponentC InterfaceA componentC;
}

class LordOfTheComponents {
    @Inject InterfaceA[] components;
}

class ComponentCharlie {
    @Inject @AssignNewInstance ComponentA componentA;
}

class OuttaTime {
    @Inject @OptionalDependency InterfaceA interfaceA;

    @Inject @OptionalDependency ComponentA componentA;

    @Inject @OptionalDependency ComponentC[] componentCs;
}

class ValuedClass {
    @Value("values.int")
    int intValue;

    @Inject ComponentA unrelated;
}

class TestInjector : ValueInjector!int {
    override int get(string key) {
        assert(key == "values.int");
        return 8;
    }
}

interface TestInterface {
}

class TestClass : TestInterface {
}

class TestClassDeux : TestInterface {
    @Inject UnrelatedClass unrelated;
}

class UnrelatedClass {
}

class FailOnCreationClass {
    this() {
        throw new Exception("This class should not be instantiated");
    }
}

class AutowiredClass {
}

class ComponentClass {
    @Inject AutowiredClass autowiredClass;
}

class ComponentCat {
    @Inject ComponentMouse mouse;
}

class ComponentMouse {
    @Inject ComponentCat cat;
}

class Eenie {
    @Inject Meenie meenie;
}

class Meenie {
    @Inject Moe moe;
}

class Moe {
    @Inject Eenie eenie;
}

class Ittie {
    @Inject Bittie bittie;
}

class Bittie {
    @Inject Bunena banana;
}

class Bunena {
    @Inject Bittie bittie;
}

interface SuperInterface {
}

class SuperImplementation : SuperInterface {
    @Inject Bunena banana;
}

interface Color {
}

class Blue : Color {
}

class Red : Color {
}

class Spiders {
    @Inject TestInterface testMember;
}

class Recursive {
    @Inject Recursive recursive;
}

class Moolah {
}

class Wants {
    @Inject Moolah moolah;
}

class John {
    @Inject Wants wants;
}

class Cocktail {
    @Inject Moolah moolah;

    Red red;

    this(Red red) {
        this.red = red;
    }
}

class Wallpaper {
    Color color;

    this(Color color) {
        this.color = color;
    }
}

class Pot {
    this(Kettle kettle) {
    }
}

class Kettle {
    this(Pot pot) {
    }
}

class Rock {
    this(Scissors scissors) {
    }
}

class Paper {
    this(Rock rock) {
    }
}

class Scissors {
    this(Paper paper) {
    }
}

class Hello {
    this(Ola ola) {
    }
}

class PostConstructionDependency {
    bool postConstructWasCalled = false;

    @PostConstruct void callMeMaybe() {
        postConstructWasCalled = true;
    }
}

class ChildOfPostConstruction : PostConstructionDependency {
}

interface ThereWillBePostConstruction {
    @PostConstruct void constructIt();
}

class ButThereWontBe : ThereWillBePostConstruction {
    bool postConstructWasCalled = false;

    override void constructIt() {
        postConstructWasCalled = true;
    }
}

class PostConstructWithAutowiring {
    @Inject private PostConstructionDependency dependency;

    @Value("")
    private int theNumber = 1;

    @PostConstruct void doIt() {
        assert(theNumber == 8783);
        assert(dependency !is null);
    }
}

class PreDestroyerOfFates {
    bool preDestroyWasCalled = false;

    @PreDestroy void callMeMaybe() {
        preDestroyWasCalled = true;
    }
}

class PostConstructingIntInjector : ValueInjector!int {
    int get(string key) {
        return 8783;
    }
}

interface Fruit {
    string getShape();
}

interface Animal {
    string getYell();
}

class Banana {
    string color;

    this(string color) {
        this.color = color;
    }
}

class Apple {
}

class Pear : Fruit {
    override string getShape() {
        return "Pear shaped";
    }
}

class Rabbit : Animal {
    override string getYell() {
        return "Squeeeeeel";
    }
}

class Wolf : Animal {
    override string getYell() {
        return "Wooooooooooo";
    }
}

class PieChart {
}

class CakeChart : PieChart {
}

class ClassWrapper {
    Object someClass;

    this(Object someClass) {
        this.someClass = someClass;
    }
}

class ClassWrapperWrapper {
    ClassWrapper wrapper;

    this(ClassWrapper wrapper) {
        this.wrapper = wrapper;
    }
}

class SimpleContext : ApplicationContext {
    override void registerDependencies(shared(DependencyContainer) container) {
        container.register!CakeChart;
    }

    @Component Apple apple() {
        return new Apple();
    }
}

class ComplexAutowiredTestContext : ApplicationContext {

    @Inject private Apple apple;

    @Inject protected ClassWrapper classWrapper;

    override void registerDependencies(shared(DependencyContainer) container) {
        container.register!Apple;
    }

    @Component ClassWrapper wrapper() {
        return new ClassWrapper(apple);
    }

    @Component ClassWrapperWrapper wrapperWrapper() {
        return new ClassWrapperWrapper(classWrapper);
    }

}

class AutowiredTestContext : ApplicationContext {

    @Inject private Apple apple;

    @Component ClassWrapper wrapper() {
        return new ClassWrapper(apple);
    }
}

class TestContext : ApplicationContext {

    @Component Banana banana() {
        return new Banana("Yellow");
    }

    Apple apple() {
        return new Apple();
    }

    @Component @RegisterByType!Fruit Pear pear() {
        return new Pear();
    }

    @Component @RegisterByType!Animal Rabbit rabbit() {
        return new Rabbit();
    }

    @Component @RegisterByType!Animal Wolf wolf() {
        return new Wolf();
    }

    @Component @Prototype PieChart pieChart() {
        return new PieChart();
    }
}

class TestImplementation : TestInterface {
    string someContent = "";
}

class SomeOtherClassThen {
}

class ClassWithConstructor {
    TestImplementation testImplementation;

    this(TestImplementation testImplementation) {
        this.testImplementation = testImplementation;
    }
}

class ClassWithMultipleConstructors {
    SomeOtherClassThen someOtherClassThen;
    TestImplementation testImplementation;

    this(SomeOtherClassThen someOtherClassThen) {
        this.someOtherClassThen = someOtherClassThen;
    }

    this(SomeOtherClassThen someOtherClassThen, TestImplementation testImplementation) {
        this.someOtherClassThen = someOtherClassThen;
        this.testImplementation = testImplementation;
    }
}

class ClassWithConstructorWithMultipleParameters {
    SomeOtherClassThen someOtherClassThen;
    TestImplementation testImplementation;

    this(SomeOtherClassThen someOtherClassThen, TestImplementation testImplementation) {
        this.someOtherClassThen = someOtherClassThen;
        this.testImplementation = testImplementation;
    }
}

class ClassWithPrimitiveConstructor {
    SomeOtherClassThen someOtherClassThen;

    this(string willNotBePicked) {
    }

    this(SomeOtherClassThen someOtherClassThen) {
        this.someOtherClassThen = someOtherClassThen;
    }
}

class ClassWithEmptyConstructor {
    SomeOtherClassThen someOtherClassThen;

    this() {
    }

    this(SomeOtherClassThen someOtherClassThen) {
        this.someOtherClassThen = someOtherClassThen;
    }
}

class ClassWithNonInjectableConstructor {
    this(string myName) {
    }
}

class ClassWithStructConstructor {
    SomeOtherClassThen someOtherClassThen;

    this(Thing willNotBePicked) {
    }

    this(SomeOtherClassThen someOtherClassThen) {
        this.someOtherClassThen = someOtherClassThen;
    }
}

class TestType {
}

class Dependency {
}

struct Thing {
    int x;
}

class MyConfig {
    @Value("conf.stuffs")
    int stuffs;

    @Value("conf.name")
    string name;

    @Value("conf.thing")
    Thing thing;
}

class ConfigWithDefaults {
    @Value("conf.missing")
    int noms = 9;
}

class ConfigWithMandatory {
    @MandatoryValue("conf.mustbethere")
    int nums;
}

class IntInjector : ValueInjector!int {
    override int get(string key) {
        assert(key == "conf.stuffs");
        return 364;
    }
}

class StringInjector : ValueInjector!string {
    override string get(string key) {
        assert(key == "conf.name");
        return "Le Chef";
    }
}

class ThingInjector : ValueInjector!Thing {
    override Thing get(string key) {
        assert(key == "conf.thing");
        return Thing(8899);
    }
}

class DefaultIntInjector : ValueInjector!int {
    override int get(string key) {
        throw new ValueNotAvailableException(key);
    }
}

class MandatoryAvailableIntInjector : ValueInjector!int {
    override int get(string key) {
        return 7466;
    }
}

class MandatoryUnavailableIntInjector : ValueInjector!int {
    override int get(string key) {
        throw new ValueNotAvailableException(key);
    }
}

class DependencyInjectedIntInjector : ValueInjector!int {
    @Inject Dependency dependency;

    override int get(string key) {
        return 2345;
    }
}

class CircularIntInjector : ValueInjector!int {
    @Inject ValueInjector!int dependency;

    private int count = 0;

    override int get(string key) {
        count += 1;
        if (count >= 3) {
            return count;
        }
        return dependency.get(key);
    }
}

class ValueInjectedIntInjector : ValueInjector!int {
    @Value("five")
    int count = 0;

    override int get(string key) {
        if (key == "five") {
            return 5;
        }

        return count;
    }
}

class DependencyValueInjectedIntInjector : ValueInjector!int {
    @Inject ConfigWithDefaults config;

    override int get(string key) {
        if (key == "conf.missing") {
            return 8899;
        }

        return 0;
    }
}

class TemplatedComponent(T) {
    @Inject T instance;
}

class CircularTemplateComponentA : TemplatedComponent!CircularTemplateComponentB {

}

class CircularTemplateComponentB : TemplatedComponent!CircularTemplateComponentA {

}

class ClassWithTemplatedConstructorArg(T) {
    TemplatedComponent!T dependency;

    this(TemplatedComponent!T assignedDependency) {
        this.dependency = assignedDependency;
    }
}

class Grandma {

}

class Mommy : Grandma {

}

class Kid : Mommy {

}

class AutowiredMethod {
    @Inject
    int lala() {
        return 42;
    }

    @Inject
    int lala(int valla) {
        return valla;
    }
}

class WithAutowireAttribute {
    @Autowire ComponentA componentA;
}
