package com.pm.authservice.service;

import com.pm.authservice.dto.LoginRequestDTO;
import com.pm.authservice.util.JwtUtil;
import io.jsonwebtoken.JwtException;
import java.util.Optional;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

  private final AuthenticationManager authenticationManager;
  private final JwtUtil jwtUtil;
  private final UserService userService;

  public AuthService(AuthenticationManager authenticationManager, 
                     JwtUtil jwtUtil,
                     UserService userService) {
    this.authenticationManager = authenticationManager;
    this.jwtUtil = jwtUtil;
    this.userService = userService;
  }

  public Optional<String> authenticate(LoginRequestDTO loginRequestDTO) {
    try {
      // Create authentication token
      UsernamePasswordAuthenticationToken authToken = 
          new UsernamePasswordAuthenticationToken(
              loginRequestDTO.getEmail(), 
              loginRequestDTO.getPassword()
          );
      
      // This triggers Spring Security's authentication flow
      // - Calls UserDetailsService.loadUserByUsername()
      // - Uses PasswordEncoder to check password
      // - Creates authenticated Authentication object
      Authentication authentication = authenticationManager.authenticate(authToken);
      
      // Get user details from authentication
      UserDetails userDetails = (UserDetails) authentication.getPrincipal();
      
      // Extract role (you might need to adjust this based on your UserDetails implementation)
      String role = userDetails.getAuthorities().iterator().next().getAuthority();
      role = role.replace("ROLE_", ""); // Remove ROLE_ prefix if present
      
      // Generate token
      String token = jwtUtil.generateToken(userDetails.getUsername(), role);
      return Optional.of(token);
      
    } catch (BadCredentialsException e) {
      // Log failed attempt (optional)
      System.out.println("Authentication failed for: " + loginRequestDTO.getEmail());
      return Optional.empty();
    }
  }

  public boolean validateToken(String token) {
    try {
      jwtUtil.validateToken(token);
      return true;
    } catch (JwtException e){
      return false;
    }
  }
}