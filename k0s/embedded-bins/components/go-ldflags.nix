# ADR-0016 drops upstream's static linking rather than reproducing it, so
# anything else in build_go_ldflags_extra would be a pin dropped in silence.
# etcd comments the variable out, which is why an absent field passes too.
component:
let
  staticLinking = "-extldflags=-static";
  extra = component.build_go_ldflags_extra or staticLinking;
in
assert extra == staticLinking;
component.build_go_ldflags or ""
