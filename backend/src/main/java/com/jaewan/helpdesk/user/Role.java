package com.jaewan.helpdesk.user;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter // displayName을 조회하는 메서드 생성
@RequiredArgsConstructor // final 필드를 초기화하는 생성자 자동 생성
public enum Role {

    REQUESTER("요청자"),
    ASSIGNEE("담당자"),
    ADMIN("관리자");

    private final String displayName; // 각 권한이 가지는 화면 표시명
}