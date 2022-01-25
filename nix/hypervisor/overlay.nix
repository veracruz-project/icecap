self: super: {
  icecap = super.icecap.overrideScope (import ./scope);
}
