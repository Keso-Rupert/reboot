module search::Search

import Prelude;
import ParseTree;
import lang::java::\syntax::Java18;

bool isTest(Tree tree) = /(Annotation)`@Test` := tree;

bool containsAutowired(Tree tree) = /(Annotation)`@Autowired` := tree;

list[UnannType] findConstructor(list[Tree] parseTrees, UnannType ty) {
  constructorArguments = [];
  Identifier class = [Identifier]"<trim("<ty>")>";
  
  for (tree <- parseTrees) {
    visit (tree) {
      case (NormalClassDeclaration)`<ClassModifier* cm> class <Identifier id> <TypeParameters? t><Superclass? su><Superinterfaces? sInf><ClassBody cb>`: {
        if (id == class) {
          constructorArguments += findConstructorArguments(tree);
        }
      }
    }
  }
  
  return constructorArguments;
}

list[UnannType] findConstructorArguments(Tree tree) {
  constructorArguments = [];
  
  visit (tree) {
    case e:(FieldDeclaration)`<Annotation _> <FieldModifier* _> <UnannType t><VariableDeclaratorId _>;` : constructorArguments += t;
    case f:(FieldDeclaration)`<Annotation _> <UnannType t><VariableDeclaratorId _>;` : constructorArguments += t;
  }
  
  return constructorArguments;
}
