package com.jimdo.template.config

import com.jimdo.spring.security.simpletokens.webmvc.simpleBearerToken
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.config.web.servlet.invoke
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder

@Configuration
class SecurityConfig(
    @Value("\${spring.application.name}") private val serviceName: String,
    @Value("\${authentication.docs.user}") private val docsUser: String,
    @Value("\${authentication.docs.password}") private val docsPassword: String,
    @Value("\${authentication.api.user}") private val apiUser: String,
    @Value("\${authentication.api.token}") private val apiToken: String
) : WebSecurityConfigurerAdapter() {
    companion object {
        const val ROLE_API_USER = "API_USER"
        const val ROLE_DOCS_USER = "DOCS_USER"
    }

    private val passwordEncoder = BCryptPasswordEncoder()

    override fun configure(auth: AuthenticationManagerBuilder) {
        auth.inMemoryAuthentication()
            .passwordEncoder(passwordEncoder)
            .withUser(docsUser)
            .password(passwordEncoder.encode(docsPassword))
            .roles(ROLE_DOCS_USER)
            .and()
            .withUser(apiUser)
            .password(passwordEncoder.encode(apiToken))
            .roles(ROLE_API_USER)
    }

    override fun configure(http: HttpSecurity) {
        http {
            // the token implementation does not prepend ROLE_ for some reason,
            // other functions automatically append it though so for this case
            // it needs to be prepended manually
            simpleBearerToken(expectedToken = apiToken, "ROLE_$ROLE_API_USER")
            httpBasic {
                realmName = serviceName
            }

            authorizeRequests {
                authorize("/health", permitAll)
                authorize("/metrics", permitAll)
                authorize("/docs/**", hasRole(ROLE_DOCS_USER))
                authorize("/api/**", hasRole(ROLE_API_USER))
                authorize("/**", denyAll)
            }

            csrf {
                disable()
            }

            sessionManagement {
                sessionCreationPolicy = SessionCreationPolicy.STATELESS
            }
        }
    }
}
