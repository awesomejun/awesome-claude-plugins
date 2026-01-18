---
name: make-statusline-awesome
description: Claude Code statusline을 대화형으로 설정합니다. Catppuccin Mocha 테마의 아름다운 4-line statusline을 step-by-step으로 설치하고 커스터마이즈합니다.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
argument-hint: "[customize]"
---

# Statusline Setup Wizard

Claude Code의 statusline을 설정하는 대화형 마법사를 실행합니다.

## 기본 동작

1. **현재 설정 확인**: `~/.claude/settings.json`에서 기존 statusline 설정 확인
2. **기존 설정 백업**: 이미 statusline이 있으면 자동으로 백업
3. **Step-by-step 질문**: AskUserQuestion으로 사용자 선호도 파악
4. **스크립트 설치**: 선택에 따라 statusline 스크립트 설치
5. **설정 적용**: settings.json 업데이트

## 🔄 기존 Statusline 백업 (중요!)

**기존 statusline이 설정되어 있는 경우 반드시 다음 순서로 처리합니다:**

### Step 0: 기존 설정 감지 및 백업

1. `~/.claude/settings.json`에서 현재 `statusLine` 설정 확인
2. 기존 설정이 있으면:
   - 기존 스크립트 파일을 `~/.claude/statusline-backup-{timestamp}.sh`로 백업
   - 기존 settings.json의 statusLine 설정을 `~/.claude/statusline-backup-{timestamp}.json`으로 백업
   - 사용자에게 백업 완료 알림: "📦 기존 statusline을 백업했습니다: ~/.claude/statusline-backup-{timestamp}.sh"

**백업 명령어 예시:**
```bash
# 기존 스크립트 백업
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EXISTING_SCRIPT=$(jq -r '.statusLine.command // empty' ~/.claude/settings.json)
if [[ -n "$EXISTING_SCRIPT" && -f "${EXISTING_SCRIPT/#\~/$HOME}" ]]; then
    cp "${EXISTING_SCRIPT/#\~/$HOME}" ~/.claude/statusline-backup-${TIMESTAMP}.sh
fi

# 기존 설정 백업
jq '.statusLine' ~/.claude/settings.json > ~/.claude/statusline-backup-${TIMESTAMP}.json
```

## 설정 플로우

### Step 1: 설치 방식 선택
AskUserQuestion으로 물어봅니다:
- **기본 설치 (권장)**: Catppuccin Mocha 테마 4-line statusline 바로 설치
- **커스터마이즈**: 테마, 표시 정보, 색상 등을 선택

### Step 2: 기본 설치 선택 시
1. `${CLAUDE_PLUGIN_ROOT}/scripts/awesome-statusline.sh`를 `~/.claude/awesome-statusline.sh`로 복사
2. `~/.claude/settings.json`의 `statusLine` 필드 업데이트:
   ```json
   "statusLine": {
     "type": "command",
     "command": "~/.claude/awesome-statusline.sh"
   }
   ```
3. 스크립트에 실행 권한 부여: `chmod +x ~/.claude/awesome-statusline.sh`
4. 완료 메시지 표시

### Step 3: 커스터마이즈 선택 시
AskUserQuestion으로 순차적으로 물어봅니다:

**테마 선택:**
- Catppuccin Mocha (기본, 다크 테마)
- Catppuccin Latte (라이트 테마)
- 사용자 정의 (직접 색상 지정)

**표시할 정보 선택 (multiSelect):**
- 모델 정보 (🧠 Opus, 🎵 Sonnet, ⚡️ Haiku)
- Git 상태 (✅ clean / 🚧 dirty)
- Conda 환경 (🐍 env-name)
- Output Style (🎨 learning)
- 디렉토리 경로 (📂 path)
- Git 브랜치 (🌿 branch)
- Context 사용량 (📝 progress bar)
- API 사용량 (🚀 5H/7D progress bars)

**프로그레스 바 스타일:**
- 그라데이션 (기본)
- 단색
- 미니멀 (텍스트만)

선택에 따라 스크립트를 수정하여 설치합니다.

## 인자 처리

- **인자 없음**: 기본 설치 vs 커스터마이즈 선택
- **`customize`**: 바로 커스터마이즈 모드로 진입
- **`reset`**: 기존 설정 초기화 후 재설정
- **`restore`**: 가장 최근 백업에서 복원

## 중요 사항

- ⚠️ **기존 statusline 설정이 있으면 자동으로 백업 후 교체합니다**
- 백업 파일 위치: `~/.claude/statusline-backup-{timestamp}.*`
- 스크립트는 항상 `~/.claude/awesome-statusline.sh`에 설치됩니다
- 설정 완료 후 Claude Code 재시작이 필요합니다

## 예시 대화

### 기존 statusline이 없는 경우:
```
사용자: /make-statusline-awesome

Claude: 안녕하세요! Statusline 설정 마법사입니다. 🎨

        현재 statusline이 설정되어 있지 않습니다.
        어떻게 설정하시겠습니까?

        [기본 설치 - Catppuccin Mocha 4-line] [커스터마이즈]
```

### 기존 statusline이 있는 경우:
```
사용자: /make-statusline-awesome

Claude: 안녕하세요! Statusline 설정 마법사입니다. 🎨

        ⚠️ 기존 statusline 설정을 발견했습니다:
        - 스크립트: ~/.claude/my-old-statusline.sh

        📦 기존 설정을 백업합니다...
        ✅ 백업 완료: ~/.claude/statusline-backup-20250118_211500.sh

        새 Awesome Statusline을 설치하시겠습니까?

        [기본 설치 - Catppuccin Mocha 4-line] [커스터마이즈]

사용자: 기본 설치

Claude: ✅ Awesome Statusline이 설치되었습니다!

        📦 백업: ~/.claude/statusline-backup-20250118_211500.sh
        📁 새 스크립트: ~/.claude/awesome-statusline.sh
        ⚙️ 설정: ~/.claude/settings.json

        💡 이전 statusline으로 돌아가려면: /make-statusline-awesome restore

        Claude Code를 재시작하면 새 statusline이 적용됩니다.
```

## 복원 (Restore)

**⚠️ 중요: 복원 시 statusLine 설정만 복원하고, 다른 settings.json 설정은 그대로 유지합니다!**

### 복원 프로세스

1. `~/.claude/statusline-backup-*.json`에서 백업된 `statusLine` 설정 읽기
2. `~/.claude/statusline-backup-*.sh` 스크립트를 원래 위치로 복사
3. `~/.claude/settings.json`에서 **statusLine 필드만** 백업된 값으로 교체
4. 다른 설정 (`hooks`, `enabledPlugins`, `outputStyle` 등)은 **절대 변경하지 않음**

**복원 명령어 예시:**
```bash
# 백업된 statusLine 설정 읽기
BACKUP_CONFIG=$(cat ~/.claude/statusline-backup-20250118_211500.json)

# settings.json에서 statusLine 필드만 교체 (다른 설정 유지)
jq --argjson backup "$BACKUP_CONFIG" '.statusLine = $backup' ~/.claude/settings.json > /tmp/settings.tmp
mv /tmp/settings.tmp ~/.claude/settings.json

# 백업된 스크립트 복원
cp ~/.claude/statusline-backup-20250118_211500.sh ~/.claude/my-old-statusline.sh
```

### 예시 대화

```
사용자: /make-statusline-awesome restore

Claude: 📦 백업 파일을 찾았습니다:
        1. statusline-backup-20250118_211500.sh (가장 최근)
        2. statusline-backup-20250117_143000.sh

        어떤 백업으로 복원하시겠습니까?

        [가장 최근 백업으로 복원] [목록에서 선택]

사용자: 가장 최근 백업으로 복원

Claude: ✅ 복원 완료!

        📁 스크립트 복원: ~/.claude/my-old-statusline.sh
        ⚙️ settings.json의 statusLine 설정만 복원됨
        ℹ️ 다른 설정 (hooks, plugins 등)은 변경되지 않았습니다.

        Claude Code를 재시작하면 이전 statusline이 적용됩니다.
```

## 에러 처리

- `jq` 미설치: Homebrew로 설치 안내
- 권한 오류: sudo 또는 권한 변경 안내
- settings.json 파싱 실패: 백업 후 수동 수정 안내
- 백업 파일 없음: 복원 불가 안내
