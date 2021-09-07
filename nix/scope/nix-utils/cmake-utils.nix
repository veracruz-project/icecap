{ }:

{

  types = rec {

    mk = type: value: {
      inherit type value;
    };

    STRING = mk "STRING";
    BOOL = mk "BOOL";
    INTERNAL = mk "INTERNAL";
    ON = BOOL "ON";
    OFF = BOOL "OFF";

  };

}
