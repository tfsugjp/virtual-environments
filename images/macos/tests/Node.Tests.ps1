Import-Module "$PSScriptRoot/../helpers/Common.Helpers.psm1"
Import-Module "$PSScriptRoot/../helpers/Tests.Helpers.psm1"

Describe "Node.js" {
    BeforeAll {
        $os = Get-OSVersion
        $expectedNodeVersion = if ($os.IsHigherThanMojave) { "v14.*" } else { "v8.*" }
    }

    It "Node.js is installed" {
        "node --version" | Should -ReturnZeroExitCode
    }

    It "Node.js $expectedNodeVersion is default" {
        (Get-CommandResult "node --version").Output | Should -BeLike $expectedNodeVersion
    }

    It "NPM is installed" {
        "npm --version" | Should -ReturnZeroExitCode
    }

    It "Yarn is installed" {
        "yarn --version" | Should -ReturnZeroExitCode
    }
}

Describe "nvm" {
    BeforeAll {
        $nvmPath = Join-Path $env:HOME ".nvm" "nvm.sh"
        $nvmInitCommand = ". $nvmPath > /dev/null 2>&1 || true"
    }

    It "nvm is installed" {
        $nvmPath | Should -Exist
        "$nvmInitCommand && nvm --version" | Should -ReturnZeroExitCode
    }

    Context "nvm versions" {
        $NVM_VERSIONS = @(6, 8, 10, 12)
        $testCases = $NVM_VERSIONS | ForEach-Object { @{NvmVersion = $_} }

        It "<NvmVersion>" -TestCases $testCases {
            param (
                [string] $NvmVersion
            )

            "$nvmInitCommand && nvm ls $($NvmVersion)" | Should -ReturnZeroExitCode
        }
    }
}
