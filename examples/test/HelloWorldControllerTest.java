package org.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;

public class HelloWorldControllerTest {
  @InjectMocks
  private HelloWorldController helloWorldController;
  @Mock
  private A a;
  @Mock(answer = Answers.RETURNS_DEEP_STUBS)
  private B b;
  
  @Test
  public void testSomething() {
    assertThat(1, 1);
  }
}
