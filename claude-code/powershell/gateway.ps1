# Claude Code Gateway 切换函数
# 用法: gw on [glm|xiaomi|ds] | gw off | gw
# 加载方式: . D:\GitHub\gateway.ps1  (点号source，不能直接运行)

function gw {
    $GW_URLS = @{
        glm    = "https://open.bigmodel.cn/api/anthropic"
        xiaomi = "https://token-plan-cn.xiaomimimo.com/anthropic"
        ds     = "https://api.deepseek.com/anthropic"
    }

    $GW_KEY = @{
        glm    = "change me"
        xiaomi = "change me"
        ds     = "change me"
    }

    function _unset_vars {
        $vars = @(
            'ANTHROPIC_BASE_URL', 'ANTHROPIC_AUTH_TOKEN',
            'CLAUDE_CODE_DISABLE_1M_CONTEXT',
            'CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS',
            'CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK',
            'ANTHROPIC_DEFAULT_HAIKU_MODEL', 'ANTHROPIC_DEFAULT_SONNET_MODEL',
            'ANTHROPIC_DEFAULT_OPUS_MODEL', 'CLAUDE_CODE_SUBAGENT_MODEL',
            'ANTHROPIC_CUSTOM_MODEL_OPTION', 'ANTHROPIC_CUSTOM_MODEL_OPTION_NAME',
            'ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION'
        )
        foreach ($v in $vars) {
            Remove-Item "Env:$v" -ErrorAction SilentlyContinue
        }
    }

    switch ($args[0]) {
        'on' {
            $mode = if ($args.Count -ge 2) { $args[1] } else { 'glm' }
            if (-not $GW_URLS.ContainsKey($mode)) {
                Write-Host "unknown mode: $mode, available: $($GW_URLS.Keys -join ', ')"
                return
            }
            _unset_vars
            $env:ANTHROPIC_BASE_URL = $GW_URLS[$mode]
            $env:ANTHROPIC_AUTH_TOKEN = $GW_KEY[$mode]

            if ($mode -eq 'glm') {
                $env:CLAUDE_CODE_DISABLE_1M_CONTEXT = "1"
                $env:ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5.1"
                $env:ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5-turbo"
                $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-4.5-air"
                $env:ANTHROPIC_CUSTOM_MODEL_OPTION = "glm-4.7"
                $env:ANTHROPIC_CUSTOM_MODEL_OPTION_NAME = "glm-4.7"
                $env:ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION = "GLM-4.7 is an open-source large language model developed by Z.ai"
            }

            if ($mode -eq 'xiaomi') {
                $env:ANTHROPIC_DEFAULT_OPUS_MODEL = "mimo-v2.5-pro[1m]"
                $env:ANTHROPIC_DEFAULT_SONNET_MODEL = "mimo-v2.5-pro"
                $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "mimo-v2.5"
                # 移除实验性 beta 头和字段
                # $env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1"
                $env:CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK = "1"
            }

            if ($mode -eq 'ds') {
                $env:ANTHROPIC_DEFAULT_OPUS_MODEL = "deepseek-v4-pro[1m]"
                $env:ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-pro[1m]"
                $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-v4-flash"
                $env:CLAUDE_CODE_SUBAGENT_MODEL = "deepseek-v4-flash"
                $env:CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK = "1"
            }

            Write-Host "gateway: on [$mode]"
        }

        'off' {
            _unset_vars
            Write-Host "gateway: off"
        }

        default {
            if ($env:ANTHROPIC_BASE_URL) {
                Write-Host "gateway: on → $env:ANTHROPIC_BASE_URL"
            } else {
                Write-Host "gateway: off"
            }
            Write-Host "usage: gw on [glm|xiaomi|ds] | gw off"
        }
    }
}
