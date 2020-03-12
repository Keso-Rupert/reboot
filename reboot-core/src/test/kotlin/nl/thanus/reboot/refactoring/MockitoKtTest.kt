package nl.thanus.reboot.refactoring

import com.github.javaparser.StaticJavaParser
import com.github.javaparser.resolution.declarations.ResolvedReferenceTypeDeclaration
import com.github.javaparser.symbolsolver.JavaSymbolSolver
import com.github.javaparser.symbolsolver.resolution.typesolvers.MemoryTypeSolver
import io.mockk.mockk
import org.junit.jupiter.api.Test

internal class MockitoKtTest : ReBootBase() {

    @Test
    fun `Rewrite @Mock including import`() {
        val code = """
            import org.mockito.Mock;
            
            class UsersControllerTest {
                @Mock
                private UsersService usersService;
            }
        """.trimIndent()
        val compilationUnit = StaticJavaParser.parse(code)

        rewriteMockitoFieldInjections(compilationUnit)

        val expectedCode = """
            import org.mockito.Mockito;
            
            class UsersControllerTest {
                private UsersService usersService = Mockito.mock(UsersService.class);
            }
        """.trimIndent()

        assertRefactored(compilationUnit, expectedCode)
    }

    @Test
    fun `Rewrite @Spy including import`() {
        val code = """
            import org.mockito.Spy;
            
            class UsersControllerTest {
                @Spy
                private UsersService usersService;
            }
        """.trimIndent()
        val compilationUnit = StaticJavaParser.parse(code)

        rewriteMockitoFieldInjections(compilationUnit)

        val expectedCode = """
            import org.mockito.Mockito;
            
            class UsersControllerTest {
                private UsersService usersService = Mockito.spy(new UsersService());
            }
        """.trimIndent()

        assertRefactored(compilationUnit, expectedCode)
    }

    @Test
    fun `Rewrite @InjectMocks with object creation`() {
        val code = """
            import org.mockito.InjectMocks;
            
            class UsersControllerTest {
                @InjectMocks
                private UsersController usersController;
            }
        """.trimIndent()

        val typeDeclaration = mockk<ResolvedReferenceTypeDeclaration>()

        val memoryTypeSolver = MemoryTypeSolver()
        memoryTypeSolver.addDeclaration("example.controllers.UsersController", typeDeclaration)

        StaticJavaParser.getConfiguration().setSymbolResolver(JavaSymbolSolver(memoryTypeSolver))

        val compilationUnit = StaticJavaParser.parse(code)

        rewriteMockitoFieldInjections(compilationUnit)

        val expectedCode = """
            class UsersControllerTest {
                private UsersController usersController = new UsersController();
            }
        """.trimIndent()

        assertRefactored(compilationUnit, expectedCode)
    }

    @Test
    fun `Rewrite @InjectMocks with object creation cannot resolve`() {
        val code = """
            import org.mockito.InjectMocks;
            
            class UsersControllerTest {
                @InjectMocks
                private UsersController usersController;
            }
        """.trimIndent()

        val memoryTypeSolver = MemoryTypeSolver()
        StaticJavaParser.getConfiguration().setSymbolResolver(JavaSymbolSolver(memoryTypeSolver))

        val compilationUnit = StaticJavaParser.parse(code)

        rewriteMockitoFieldInjections(compilationUnit)

        val expectedCode = """
            class UsersControllerTest {
                private UsersController usersController = new UsersController();
            }
        """.trimIndent()

        assertRefactored(compilationUnit, expectedCode)
    }

    @Test
    fun `Should not add Mockito import when there is already one`() {
        val code = """
            import org.mockito.Mock;
            import org.mockito.Mockito;
            
            class UsersControllerTest {
                @Mock
                private UsersService usersService;
            }
        """.trimIndent()
        val compilationUnit = StaticJavaParser.parse(code)

        rewriteMockitoFieldInjections(compilationUnit)

        val expectedCode = """
            import org.mockito.Mockito;
            
            class UsersControllerTest {
                private UsersService usersService = Mockito.mock(UsersService.class);
            }
        """.trimIndent()

        assertRefactored(compilationUnit, expectedCode)
    }
}
