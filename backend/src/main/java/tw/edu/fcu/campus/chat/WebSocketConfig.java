package tw.edu.fcu.campus.chat;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.standard.ServletServerContainerFactoryBean;

import java.util.Arrays;

/** WebSocket 端點 /ws：原生 WebSocket 加 JSON，不用 STOMP（架構文件 AD-07） */
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    private final PushGateway gateway;
    private final String[] origins;

    public WebSocketConfig(PushGateway gateway, @Value("${app.allowed-origins}") String allowedOrigins) {
        this.gateway = gateway;
        this.origins = Arrays.stream(allowedOrigins.split(",")).map(String::trim).filter(x -> !x.isEmpty()).toArray(String[]::new);
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(gateway, "/ws").setAllowedOriginPatterns(origins);
    }

    /** 用戶端只送 auth 與 ping，訊息很小；70 秒沒有任何訊息就當成斷線（用戶端每 25 秒 ping 一次） */
    @Bean
    ServletServerContainerFactoryBean webSocketContainer() {
        ServletServerContainerFactoryBean c = new ServletServerContainerFactoryBean();
        c.setMaxTextMessageBufferSize(8 * 1024);
        c.setMaxSessionIdleTimeout(70_000L);
        return c;
    }
}
