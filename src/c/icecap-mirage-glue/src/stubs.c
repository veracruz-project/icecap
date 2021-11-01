#include <autoconf.h>

#include <assert.h>

#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include <icecap-mirage-glue.h>

CAMLprim value
stub_wfe(value unit) {
    CAMLparam1(unit);
    impl_wfe();
    CAMLreturn(Val_unit);
}

CAMLprim value
caml_get_monotonic_time(value unit)
{
    CAMLparam1(unit);
    uint64_t now = impl_get_time_ns();
    CAMLreturn(caml_copy_int64(now));
}

CAMLprim value
stub_set_timeout_ns(value v_d)
{
    CAMLparam1(v_d);
    uint64_t d = Int64_val(v_d);
    impl_set_timeout_ns(d);
    CAMLreturn(Val_unit);
}

CAMLprim value
stub_num_net_ifaces(value unit)
{
    CAMLparam1(unit);
    CAMLreturn(Val_int(impl_num_net_ifaces()));
}

CAMLprim value
stub_net_iface_poll(value v_net_iface_id) {
    CAMLparam1(v_net_iface_id);
    int net_iface_id = Int_val(v_net_iface_id);
    CAMLreturn(Val_bool(impl_net_iface_poll(net_iface_id)));
}

CAMLprim value
stub_net_iface_rx(value v_net_driver_id) {
    CAMLparam1(v_net_driver_id);
    CAMLlocal1(ret);
    int net_driver_id = Int_val(v_net_driver_id);
    // TODO is the alloc co-stub sound for use with CAML* macros?
    ret = (value)impl_net_iface_rx(net_driver_id);
    CAMLreturn(ret);
}

CAMLprim value
stub_net_iface_tx(value v_net_iface_id, value v_buf) {
    CAMLparam2(v_net_iface_id, v_buf);
    int net_iface_id = Int_val(v_net_iface_id);
    size_t n = caml_string_length(v_buf);
    impl_net_iface_tx(net_iface_id, (char *)Bytes_val(v_buf), n);
    CAMLreturn(Val_unit);
}
