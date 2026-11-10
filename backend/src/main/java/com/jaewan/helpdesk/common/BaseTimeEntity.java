package com.jaewan.helpdesk.common;

import jakarta.persistence.Column;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.MappedSuperclass;

import lombok.Getter;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Getter // 조회 메서드 생성
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class) // 엔티티 생명주기 이벤트 감지
public abstract class BaseTimeEntity {
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false) // DB 컬럼과 연결
    private LocalDateTime createdAt;
}
