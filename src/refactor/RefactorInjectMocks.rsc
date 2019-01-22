module refactor::RefactorInjectMocks

import ParseTree;
import lang::java::\syntax::Java18;
import String;
import IO;
import Prelude;
import search::Search;

Tree refactorInjectMocks(Tree tree, list[Tree] parseTrees) {
  tree = rewriteMockitoImports(tree);
  
  tree = rewriteMockAnnotation(tree);
  tree = rewriteInjectMocksAnnotation(tree, parseTrees);
  tree = rewriteSpyAnnotation(tree);
  
  return tree;
}

Tree rewriteMockitoImports(Tree tree) {
  return innermost visit (tree) {
    case (Imports)`<ImportDeclaration* i1>
                  'import org.mockito.Mock;
                  '<ImportDeclaration* i2>`
      => (Imports)`<ImportDeclaration* i1>
                  'import org.mockito.Mockito;
                  '<ImportDeclaration* i2>`
    case (Imports)`<ImportDeclaration* im1>
                  'import org.mockito.Spy;
                  '<ImportDeclaration* im2>`
      => (Imports)`<ImportDeclaration* im1>
                  'import org.mockito.Mockito;
                  '<ImportDeclaration* im2>`
    case (Imports)`<ImportDeclaration* imp1>
                  'import org.mockito.InjectMocks;
                  '<ImportDeclaration* imp2>`
      => (Imports)`<ImportDeclaration* imp1>
                  '<ImportDeclaration* imp2>`
    case (Imports)`<ImportDeclaration* impo1>
                  'import org.mockito.Mockito;
                  '<ImportDeclaration* impo2>`
      => (Imports)`<ImportDeclaration* impo1>
                  '<ImportDeclaration* impo2>`
      when /(SingleTypeImportDeclaration)`import org.mockito.Mockito;` := impo1
  }
}

Tree rewriteMockAnnotation(Tree tree) {
  VariableInitializer createMockObject(UnannType t) = [VariableInitializer]"Mockito.mock(<trim("<t>")>.class)";
  VariableInitializer createMockObjectWithAnswer(UnannType t, ElementValue e) = [VariableInitializer]"Mockito.mock(<trim("<t>")>.class, <e>)";
  
  return visit (tree) {
    case (FieldDeclaration)`@Mock <FieldModifier* f> <UnannType t><VariableDeclaratorId i>;`
      => (FieldDeclaration)`<FieldModifier* f> <UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;`
      when VariableInitializer varInit := createMockObject(t)
    case (FieldDeclaration)`@Mock <UnannType t><VariableDeclaratorId i>;`
      => (FieldDeclaration)`<UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;`
      when VariableInitializer varInit := createMockObject(t)

    case (FieldDeclaration)`@Mock(answer = <ElementValue e>) <FieldModifier* f> <UnannType t><VariableDeclaratorId i>;`
      => (FieldDeclaration)`<FieldModifier* f> <UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;`
      when VariableInitializer varInit := createMockObjectWithAnswer(t, e)
    case (FieldDeclaration)`@Mock(answer = <ElementValue e>) <UnannType t><VariableDeclaratorId i>;`
      => (FieldDeclaration)`<UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;`
      when VariableInitializer varInit := createMockObjectWithAnswer(t, e)
 }
}

Tree rewriteSpyAnnotation(Tree tree) {
  VariableInitializer createVarInitWithSpy(VariableInitializer varInit) = [VariableInitializer]"Mockito.spy(<varInit>)";
  
  return visit (tree) {
    case (FieldDeclaration)`@Spy <FieldModifier* f> <UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;`
      => (FieldDeclaration)`<FieldModifier* f> <UnannType t><VariableDeclaratorId i> = <VariableInitializer vInit>;`
      when VariableInitializer vInit := createVarInitWithSpy(varInit)
    case (FieldDeclaration)`@Spy <UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;`
      => (FieldDeclaration)`<UnannType t><VariableDeclaratorId i> = <VariableInitializer vInit>;`
      when VariableInitializer vInit := createVarInitWithSpy(varInit)
  }
}

Tree rewriteInjectMocksAnnotation(Tree tree, list[Tree] parseTrees) { 
  return visit (tree) {
    case (FieldDeclaration)`@InjectMocks <FieldModifier* f> <UnannType t><VariableDeclaratorId i>;`
      => (FieldDeclaration)`<FieldModifier* f> <UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;`
      when VariableInitializer varInit := createObjectInitialization(tree, t, parseTrees)
    case (FieldDeclaration)`@InjectMocks <UnannType t><VariableDeclaratorId i>;`
      => (FieldDeclaration)`<UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;`
      when VariableInitializer varInit := createObjectInitialization(tree, t, parseTrees)
  }
}

VariableInitializer createObjectInitialization(Tree tree, UnannType t, list[Tree] parseTrees) {
  list[UnannType] constructorArgs = findConstructor(parseTrees, t);
  
  map[UnannType, VariableDeclaratorId] foundDeps = ();
  
  visit (tree) {
    case (FieldDeclaration)`<FieldModifier* f> <UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;` : foundDeps += (t: i);
    case (FieldDeclaration)`<UnannType t><VariableDeclaratorId i> = <VariableInitializer varInit>;`: foundDeps += (t: i);
  }
  
  list[str] args = [];
  for (UnannType arg <- constructorArgs) {
    if (arg in foundDeps) {
      VariableDeclaratorId varId = foundDeps[arg];
      args += "<varId>";
    }
  }
    
  str allArgs = intercalate(", ", args);
  return [VariableInitializer]"new <trim("<t>")>(<allArgs>)";
}
