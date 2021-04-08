use proc_macro2::TokenStream;
use quote::{quote, ToTokens};
use synstructure::{Structure, VariantInfo, decl_derive};

fn cardinality_of_type(ty: impl ToTokens) -> impl ToTokens {
    quote! {
        <#ty as Finite>::CARDINALITY
    }
}

fn cardinality_of_variant(variant: &VariantInfo) -> impl ToTokens {
    let mut product = quote! {
        1
    };
    for binding in variant.bindings() {
        let n = cardinality_of_type(&binding.ast().ty);
        product.extend(quote! {
            * (#n)
        })
    }
    product
}

fn cardinality_of_structure(structure: &Structure) -> impl ToTokens {
    let mut sum = quote! {
        0
    };
    for variant in structure.variants() {
        let n = cardinality_of_variant(variant);
        sum.extend(quote! {
            + (#n)
        })
    }
    sum
}

decl_derive!([Finite] => derive_finite_impl);

fn derive_finite_impl(input: Structure) -> syn::Result<TokenStream> {
    let cardinality = cardinality_of_structure(&input);
    
    let to_nat = {
        let mut n_past_variants = quote! {
            0
        };
        input.each_variant(|variant| {
            let mut expr = quote! {
                (#n_past_variants)
            };
            let mut n_past_fields = quote! {
                1
            };
            for binding in variant.bindings() {
                let ident = &binding.binding;
                expr.extend(quote! {
                    + ((#n_past_fields) * Finite::to_nat(#ident))
                });
                let n_this_field = cardinality_of_type(&binding.ast().ty);
                n_past_fields.extend(quote! {
                    * (#n_this_field)
                });
            }
            let n_this_variant = cardinality_of_variant(variant);
            n_past_variants.extend(quote! {
                + (#n_this_variant)
            });
            expr
        })
    };

    let from_nat = {
        let mut branches = quote! {
        };
        let mut n_past_variants = quote! {
            0
        };
        for variant in input.variants() {
            let expr = {
                let mut n_past_fields = quote! {
                    1
                };
                variant.construct(|field, _i| {
                    let n_this_field = cardinality_of_type(&field.ty);
                    let expr = quote! {
                        Finite::from_nat((m / (#n_past_fields)) % (#n_this_field))
                    };
                    n_past_fields.extend(quote! {
                        * (#n_this_field)
                    });
                    expr
                })
            };
            let n_this_variant = cardinality_of_variant(variant);
            branches.extend(quote! {
                if n < (#n_past_variants) + (#n_this_variant) {
                    let m = n - (#n_past_variants);
                    #expr
                } else
            });
            n_past_variants.extend(quote! {
                + (#n_this_variant)
            });
        }
        quote! {
            #branches {
                panic!("out of bounds") // TODO
            }
        }
    };

    let finite = input.gen_impl(quote! {
        // TODO use finite_set::Finite; // TODO hygene

        gen impl Finite for @Self {
            const CARDINALITY: usize = #cardinality;

            fn to_nat(&self) -> usize {
                match self {
                    #to_nat
                }
            }

            fn from_nat(n: usize) -> Self {
                #from_nat
            }
        }
    });
    Ok(quote! {
        #finite
    })
}
