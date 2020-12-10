using Clang

# FIXME: TensorFlow uses `extern c` without `ifdef __cplusplus`; remove those manually

function wrap(tensorflow)
    headers = [
        # "$tensorflow/tensorflow/stream_executor/tpu/c_api_defn.h",
        "$tensorflow/tensorflow/stream_executor/tpu/c_api_decl.h",
        # "$tensorflow/tensorflow/stream_executor/tpu/tpu_executor_c_api.h",
    ]
    clang_extraargs = String[]

    # FIXME: Clang.jl doesn't properly detect system headers
    push!(clang_extraargs, "-I/usr/lib/gcc/x86_64-pc-linux-gnu/10.2.0/include")

    context = init(;
                    headers = ["$tensorflow/tensorflow/stream_executor/tpu/tpu_executor_c_api.h"],
                    output_file = "libtpu_h.jl",
                    common_file = "libtpu_common.jl",
                    clang_includes = ["$tensorflow"],
                    clang_args = clang_extraargs,
                    header_library = x->"libtpu",
                    header_wrapped = function (top,cursor)
                        interesting = occursin("/tensorflow/", cursor) &&
                                      (occursin("/c/", cursor) || occursin("c_api", cursor))
                        @debug "$cursor: $interesting"
                        return interesting
                    end
                  )

    run(context)
end

function main()
    tf_checkout = joinpath(tempdir(), "tensorflow")
    if !isdir(tf_checkout)
        run(`git clone https://github.com/tensorflow/tensorflow $tf_checkout`)
    else
        run(`git -C $tf_checkout pull`)
    end

    cd(joinpath(dirname(@__DIR__), "lib/tpu")) do
        wrap(tf_checkout)
    end
end

isinteractive() || main()