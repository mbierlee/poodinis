/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2023 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.test.testclasses;

import poodinis;
import poodinis.test.foreigndependencies;

version (unittest) {
    class ComponentA {
    }

    class ComponentB {
        public @Inject ComponentA componentA;
    }

    interface InterfaceA {
    }

    class ComponentC : InterfaceA {
    }

    class ComponentD {
        public @Inject InterfaceA componentC = null;
        private @Inject InterfaceA _privateComponentC = null;

        public InterfaceA privateComponentC() {
            return _privateComponentC;
        }
    }

    class DummyAttribute {
    };

    class ComponentE {
        @DummyAttribute public ComponentC componentC;
    }

    class ComponentDeclarationCocktail {
        alias noomer = int;

        @Inject public ComponentA componentA;

        public void doesNothing() {
        }

        ~this() {
        }
    }

    class ComponentX : InterfaceA {
    }

    class ComponentZ : ComponentB {
    }

    class MonkeyShine {
        @Inject!ComponentX public InterfaceA component;
    }

    class BootstrapBootstrap {
        @Inject!ComponentX public InterfaceA componentX;

        @Inject!ComponentC public InterfaceA componentC;
    }

    class LordOfTheComponents {
        @Inject public InterfaceA[] components;
    }

    class ComponentCharlie {
        @Inject @AssignNewInstance public ComponentA componentA;
    }

    class OuttaTime {
        @Inject @OptionalDependency public InterfaceA interfaceA;

        @Inject @OptionalDependency public ComponentA componentA;

        @Inject @OptionalDependency public ComponentC[] componentCs;
    }

    class ValuedClass {
        @Value("values.int")
        public int intValue;

        @Inject public ComponentA unrelated;
    }

    class TestInjector : ValueInjector!int {
        public override int get(string key) {
            assert(key == "values.int");
            return 8;
        }
    }

    interface TestInterface {
    }

    class TestClass : TestInterface {
    }

    class TestClassDeux : TestInterface {
        @Inject public UnrelatedClass unrelated;
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
        @Inject public AutowiredClass autowiredClass;
    }

    class ComponentCat {
        @Inject public ComponentMouse mouse;
    }

    class ComponentMouse {
        @Inject public ComponentCat cat;
    }

    class Eenie {
        @Inject public Meenie meenie;
    }

    class Meenie {
        @Inject public Moe moe;
    }

    class Moe {
        @Inject public Eenie eenie;
    }

    class Ittie {
        @Inject public Bittie bittie;
    }

    class Bittie {
        @Inject public Bunena banana;
    }

    class Bunena {
        @Inject public Bittie bittie;
    }

    interface SuperInterface {
    }

    class SuperImplementation : SuperInterface {
        @Inject public Bunena banana;
    }

    interface Color {
    }

    class Blue : Color {
    }

    class Red : Color {
    }

    class Spiders {
        @Inject public TestInterface testMember;
    }

    class Recursive {
        @Inject public Recursive recursive;
    }

    class Moolah {
    }

    class Wants {
        @Inject public Moolah moolah;
    }

    class John {
        @Inject public Wants wants;
    }

    class Cocktail {
        @Inject public Moolah moolah;

        public Red red;

        this(Red red) {
            this.red = red;
        }
    }

    class Wallpaper {
        public Color color;

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
        public bool postConstructWasCalled = false;

        @PostConstruct public void callMeMaybe() {
            postConstructWasCalled = true;
        }
    }

    class ChildOfPostConstruction : PostConstructionDependency {
    }

    interface ThereWillBePostConstruction {
        @PostConstruct void constructIt();
    }

    class ButThereWontBe : ThereWillBePostConstruction {
        public bool postConstructWasCalled = false;

        public override void constructIt() {
            postConstructWasCalled = true;
        }
    }

    class PostConstructWithAutowiring {
        @Inject private PostConstructionDependency dependency;

        @Value("")
        private int theNumber = 1;

        @PostConstruct public void doIt() {
            assert(theNumber == 8783);
            assert(dependency !is null);
        }
    }

    class PreDestroyerOfFates {
        public bool preDestroyWasCalled = false;

        @PreDestroy public void callMeMaybe() {
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
        public string color;

        this(string color) {
            this.color = color;
        }
    }

    class Apple {
    }

    class Pear : Fruit {
        public override string getShape() {
            return "Pear shaped";
        }
    }

    class Rabbit : Animal {
        public override string getYell() {
            return "Squeeeeeel";
        }
    }

    class Wolf : Animal {
        public override string getYell() {
            return "Wooooooooooo";
        }
    }

    class PieChart {
    }

    class CakeChart : PieChart {
    }

    class ClassWrapper {
        public Object someClass;

        this(Object someClass) {
            this.someClass = someClass;
        }
    }

    class ClassWrapperWrapper {
        public ClassWrapper wrapper;

        this(ClassWrapper wrapper) {
            this.wrapper = wrapper;
        }
    }

    class SimpleContext : ApplicationContext {
        public override void registerDependencies(shared(DependencyContainer) container) {
            container.register!CakeChart;
        }

        @Component public Apple apple() {
            return new Apple();
        }
    }

    class ComplexAutowiredTestContext : ApplicationContext {

        @Inject private Apple apple;

        @Inject protected ClassWrapper classWrapper;

        public override void registerDependencies(shared(DependencyContainer) container) {
            container.register!Apple;
        }

        @Component public ClassWrapper wrapper() {
            return new ClassWrapper(apple);
        }

        @Component public ClassWrapperWrapper wrapperWrapper() {
            return new ClassWrapperWrapper(classWrapper);
        }

    }

    class AutowiredTestContext : ApplicationContext {

        @Inject private Apple apple;

        @Component public ClassWrapper wrapper() {
            return new ClassWrapper(apple);
        }
    }

    class TestContext : ApplicationContext {

        @Component public Banana banana() {
            return new Banana("Yellow");
        }

        public Apple apple() {
            return new Apple();
        }

        @Component @RegisterByType!Fruit public Pear pear() {
            return new Pear();
        }

        @Component @RegisterByType!Animal public Rabbit rabbit() {
            return new Rabbit();
        }

        @Component @RegisterByType!Animal public Wolf wolf() {
            return new Wolf();
        }

        @Component @Prototype public PieChart pieChart() {
            return new PieChart();
        }
    }

    class TestImplementation : TestInterface {
        public string someContent = "";
    }

    class SomeOtherClassThen {
    }

    class ClassWithConstructor {
        public TestImplementation testImplementation;

        this(TestImplementation testImplementation) {
            this.testImplementation = testImplementation;
        }
    }

    class ClassWithMultipleConstructors {
        public SomeOtherClassThen someOtherClassThen;
        public TestImplementation testImplementation;

        this(SomeOtherClassThen someOtherClassThen) {
            this.someOtherClassThen = someOtherClassThen;
        }

        this(SomeOtherClassThen someOtherClassThen, TestImplementation testImplementation) {
            this.someOtherClassThen = someOtherClassThen;
            this.testImplementation = testImplementation;
        }
    }

    class ClassWithConstructorWithMultipleParameters {
        public SomeOtherClassThen someOtherClassThen;
        public TestImplementation testImplementation;

        this(SomeOtherClassThen someOtherClassThen, TestImplementation testImplementation) {
            this.someOtherClassThen = someOtherClassThen;
            this.testImplementation = testImplementation;
        }
    }

    class ClassWithPrimitiveConstructor {
        public SomeOtherClassThen someOtherClassThen;

        this(string willNotBePicked) {
        }

        this(SomeOtherClassThen someOtherClassThen) {
            this.someOtherClassThen = someOtherClassThen;
        }
    }

    class ClassWithEmptyConstructor {
        public SomeOtherClassThen someOtherClassThen;

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
        public SomeOtherClassThen someOtherClassThen;

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
        public override int get(string key) {
            assert(key == "conf.stuffs");
            return 364;
        }
    }

    class StringInjector : ValueInjector!string {
        public override string get(string key) {
            assert(key == "conf.name");
            return "Le Chef";
        }
    }

    class ThingInjector : ValueInjector!Thing {
        public override Thing get(string key) {
            assert(key == "conf.thing");
            return Thing(8899);
        }
    }

    class DefaultIntInjector : ValueInjector!int {
        public override int get(string key) {
            throw new ValueNotAvailableException(key);
        }
    }

    class MandatoryAvailableIntInjector : ValueInjector!int {
        public override int get(string key) {
            return 7466;
        }
    }

    class MandatoryUnavailableIntInjector : ValueInjector!int {
        public override int get(string key) {
            throw new ValueNotAvailableException(key);
        }
    }

    class DependencyInjectedIntInjector : ValueInjector!int {
        @Inject public Dependency dependency;

        public override int get(string key) {
            return 2345;
        }
    }

    class CircularIntInjector : ValueInjector!int {
        @Inject public ValueInjector!int dependency;

        private int count = 0;

        public override int get(string key) {
            count += 1;
            if (count >= 3) {
                return count;
            }
            return dependency.get(key);
        }
    }

    class ValueInjectedIntInjector : ValueInjector!int {
        @Value("five")
        public int count = 0;

        public override int get(string key) {
            if (key == "five") {
                return 5;
            }

            return count;
        }
    }

    class DependencyValueInjectedIntInjector : ValueInjector!int {
        @Inject public ConfigWithDefaults config;

        public override int get(string key) {
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
        public TemplatedComponent!T dependency;

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
        public int lala() {
            return 42;
        }

        @Inject
        public int lala(int valla) {
            return valla;
        }
    }

    class WithAutowireAttribute {
        public @Autowire ComponentA componentA;
    }
}
