{
  source = {
    gitUrlOf = repo: "https://gitlab.com/arm-research/security/icecap/${repo}";
    keepRefOf = rev: "refs/tags/icecap/keep/${builtins.substring 0 32 rev}";
    localPathOf = repo: ../../../local + "/${repo}";
  };
}
