package com.jaewan.helpdesk.user;

import com.jaewan.helpdesk.common.BaseTimeEntity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity // 해당 클래스가 JPA에서 관리하는 엔티티라는 뜻. DB 테이블과 연결
@Table(name = "department") // 연결할 DB 테이블 이름을 명시한다
public class Department extends BaseTimeEntity {
  
  @Id // 기본키 지정
  @GeneratedValue(strategy = GenerationType.IDENTITY) // GenerationType.IDENTITY: DB의 AUTO_INCREMENT 사용
  private Long id; // SQL BIGINT

  @Column(name = "name", nullable = false, length = 50) // SQL VARCHAR(50) NOT NULL
  private String name;
}
