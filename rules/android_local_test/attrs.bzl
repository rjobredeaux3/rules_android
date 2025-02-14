# Copyright 2020 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Attributes."""

load(
    "//rules:attrs.bzl",
    _attrs = "attrs",
)

def make_attrs(additional_aspects = [], native_libs_transition = None):
    return _attrs.add(
        dict(
            deps = attr.label_list(
                allow_files = True,
                allow_rules = [
                    "aar_import",
                    "android_library",
                    "java_import",
                    "java_library",
                    "java_lite_proto_library",
                ],
                aspects = additional_aspects,
                providers = [[CcInfo], [JavaInfo]],
                doc = """
                The list of libraries to be tested as well as additional libraries to be linked
                in to the target.
                All resources, assets and manifest files declared in Android rules in the transitive
                closure of this attribute are made available in the test.

                The list of allowed rules in `deps` are `aar_import`,
                `android_library`, `java_import`, `java_library`,
                and `java_lite_proto_library`.
                """,
                cfg = native_libs_transition,
            ),
            feature_flags = attr.label_keyed_string_dict(
                doc = "This is a deprecated feature. Do not use it.",
            ),
            jvm_flags = attr.string_list(
                doc = """
                A list of flags to embed in the wrapper script generated for running this binary.
                Subject to [$(location / execpath / rootpath)](https://docs.bazel.build/versions/main/be/make-variables.html#predefined_label_variables) and
                ["Make variable"](https://docs.bazel.build/versions/main/be/make-variables.html) substitution, and
                [Bourne shell tokenization](https://docs.bazel.build/versions/main/be/common-definitions.html#sh-tokenization).

                The wrapper script for a Java binary includes a CLASSPATH definition
                (to find all the dependent jars) and invokes the right Java interpreter.
                The command line generated by the wrapper script includes the name of
                the main class followed by a `"$@"` so you can pass along other
                arguments after the classname.  However, arguments intended for parsing
                by the JVM must be specified _before_ the classname on the command
                line.  The contents of `jvm_flags` are added to the wrapper
                script before the classname is listed.

                Note that this attribute has _no effect_ on `*_deploy.jar`
                outputs.
                """,
            ),
            manifest_values = attr.string_dict(
                doc = """
                A dictionary of values to be overridden in the manifest. Any instance of ${name} in the
                manifest will be replaced with the value corresponding to name in this dictionary.
                `applicationId`, `versionCode`, `versionName`,
                `minSdkVersion`, `targetSdkVersion` and
                `maxSdkVersion` will also override the corresponding attributes
                of the manifest and
                uses-sdk tags. `packageName` will be ignored and will be set from either
                `applicationId` if
                specified or the package in the manifest.
                It is not necessary to have a manifest on the rule in order to use manifest_values.
                """,
            ),
            nocompress_extensions = attr.string_list(
                doc = "A list of file extensions to leave uncompressed in the resource apk.",
            ),
            resources = attr.label_list(
                allow_files = True,
                doc = """
                A list of data files to include in a Java jar.

                If resources are specified, they will be bundled in the jar along with the usual
                `.class` files produced by compilation. The location of the resources inside
                of the jar file is determined by the project structure. Bazel first looks for Maven's
                [standard directory layout](https://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html),
                (a "src" directory followed by a "resources" directory grandchild). If that is not
                found, Bazel then looks for the topmost directory named "java" or "javatests" (so, for
                example, if a resource is at `&lt;workspace root&gt;/x/java/y/java/z`, the
                path of the resource will be `y/java/z`. This heuristic cannot be overridden.

                Resources may be source files or generated files.

                """,
            ),
            runtime_deps = attr.label_list(
                allow_files = True,
                doc = """
                Libraries to make available to the final binary or test at runtime only.
                Like ordinary `deps`, these will appear on the runtime classpath, but unlike
                them, not on the compile-time classpath. Dependencies needed only at runtime should be
                listed here. Dependency-analysis tools should ignore targets that appear in both
                `runtime_deps` and `deps`.
                """,
                # TODO(timpeut): verify we can require JavaInfo
                # providers = [JavaInfo],
                cfg = native_libs_transition,
            ),
            srcs = attr.label_list(
                # TODO(timpeut): order independent
                # TODO(timpeut): direct compile time input
                allow_files = [".java", ".srcjar", ".properties", ".xmb"],
                doc = """
                The list of source files that are processed to create the target.
                Required except in special case described below.

                `srcs` files of type `.java` are compiled.
                _For readability's sake_, it is not good to put the name of a
                generated `.java` source file into the `srcs`.
                Instead, put the depended-on rule name in the `srcs`, as
                described below.

                `srcs` files of type `.srcjar` are unpacked and
                compiled. (This is useful if you need to generate a set of .java files with
                a genrule or build extension.)

                All other files are ignored, as long as
                there is at least one file of a file type described above. Otherwise an
                error is raised.

                The `srcs` attribute is required and cannot be empty, unless
                `runtime_deps` is specified.
                """,
            ),
            stamp = _attrs.tristate.create(
                default = _attrs.tristate.no,
                doc = """
                Whether to encode build information into the binary. Possible values:

                - `stamp = 1`: Always stamp the build information into the binary, even in
                  [`--nostamp`](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) builds. **This
                  setting should be avoided**, since it potentially kills remote caching for the
                  binary and any downstream actions that depend on it.

                - `stamp = 0`: Always replace build information by constant values. This
                  gives good build result caching.

                - `stamp = -1`: Embedding of build information is controlled by the
                  [`--[no]stamp`](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) flag.

                Stamped binaries are _not_ rebuilt unless their dependencies change.
                """,
            ),
            resource_configuration_filters = attr.string_list(
                doc = "A list of resource configuration filters, such as 'en' " +
                      "that will limit the resources in the apk to only the " +
                      "ones in the 'en' configuration.",
            ),
            densities = attr.string_list(
                doc = "Densities to filter for when building the apk. A " +
                      "corresponding compatible-screens section will also be " +
                      "added to the manifest if it does not already contain a " +
                      "superset listing.",
            ),
            env = attr.string_dict(
                doc = "A dictionary of environment variables set for the execution of the test. Will be subject to make variable and $(location) expansion.",
            ),
            robolectric_properties_file = attr.string(
                doc = "The classpath to robolectric-deps.properties file.",
                default = "${JAVA_RUNFILES}/robolectric/bazel/robolectric-deps.properties",
            ),
            test_class = attr.string(
                doc = """
                The Java class to be loaded by the test runner.

                This attribute specifies the name of a Java class to be run by
                this test. It is rare to need to set this. If this argument is omitted, the Java class
                whose name corresponds to the `name` of this
                `android_local_test` rule will be used.
                The test class needs to be annotated with `org.junit.runner.RunWith`.
                """,
            ),
            _runfiles_root_prefix = attr.label(
                doc = """
                A directory prefix that ends with a slash.

                This attribute is appended to ${JAVA_RUNFILES} when the root of path to the runfile
                resources is not directly under ${JAVA_RUNFILES}.
                """,
                default = "//rules/flags:runfiles_root_prefix",
            ),
            _flags = attr.label(
                default = "//rules/flags",
            ),
            _java_toolchain = attr.label(
                default = Label("//tools/jdk:current_java_toolchain"),
            ),
            _current_java_runtime = attr.label(
                default = Label("//tools/jdk:current_java_runtime"),
                providers = [java_common.JavaRuntimeInfo],
            ),
            _implicit_classpath = attr.label_list(
                default = [
                    Label("//tools/android:android_jar"),
                ],
            ),
        ),
        _attrs.COMPILATION,
        _attrs.DATA_CONTEXT,
        _attrs.AUTOMATIC_EXEC_GROUPS_ENABLED,
    )

ATTRS = make_attrs()
