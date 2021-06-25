/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2021 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;
import std.stdio;


class DoohickeyBase
{
}

class Doohickey : DoohickeyBase
{
}

class DoohickeyExt : Doohickey
{
}



void main()
{
    auto dependencies = new shared DependencyContainer();
    dependencies.register!(DoohickeyBase, Doohickey).initializedBy({
        writeln("Creating Doohickey via initializer delegate.");
        return new Doohickey();
    }).singleInstance();

    dependencies.register!(DoohickeyBase, DoohickeyExt).initializedBy({
        writeln("Creating Doohickey via initializer delegate.");
        return new Doohickey();
    }).singleInstance();  
    
    dependencies.resolve!Doohickey;
  
}
