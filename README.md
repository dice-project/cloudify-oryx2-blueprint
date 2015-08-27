Cloudify Oryx2 Flexiant Blueprint
=================================

An example draft of an Oryx2 blueprint, making used of the [Cloudify Flexiant Plugin](https://github.com/buhanec/cloudify-flexiant-plugin). Additionally it requires the modified [Chef Plugin with templating](https://github.com/buhanec/cloudify-chef-plugin). 

Serves to automatically set up the entire stack required for Oryx2, and Oryx2 itself, as well as a general template for any complex Chef-based future blueprints.

Input/Chef Preparations for Installation
----------------------------------------


### Inputs

The inputs currently expose the Chef configuration and assume a Chef Server/Client combination is used, and the Flexiant plugin inputs. Currently no Oryx2 configuration details can be changed through the inputs. An example inputs file would be:

```yaml
chef_version: '12.1.0-1'
chef_server: 'https://125.186.100.14/organizations/oryx'
chef_validation_user: 'oryx-validator'
chef_validation_key: |
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----
fco_api_uuid: '48194318-a78b-3066-8ae6-5e4d3803aeb'
fco_password: 'secret-password'
fco_customer: 'eb0bfd1b-253a-3190-84ff-95e21a39837e'
fco_url: 'https://cp.yourname.flexiant.net'
fco_ca_cert: False
fco_image: 'c23ace27-1249-3c4c-8acb-7d273dfae436'
fco_network:  '5a44edab-8d29-32bd-b429-5f8ca17c3f78'
fco_server_type: '4 GB / 4 CPU'
fco_cpu_count: 4
fco_ram_amount: 4096
fco_key_uuid: '1811ee73-effd-3a79-9041-32df10f22f6c'
```

Make sure the Chef server has all the required cookbooks and their dependencies in the blueprint. By default the required cookbooks are:
* `apt`
* `java`
* `hadoop`
* `apache_kafka`

For any modifications to the Chef provisioning, look at the sections below.

### Preparing the Chef Provisioning

Just like any Chef-based template for Cloudify's Chef Plugin, it requires some [documented preparations](http://getcloudify.org/guide/3.2/plugin-chef.html). However, since a modified plugin is used, a few key differences exist:

1. Chef node properties can be grouped under a common `chef_config` key, however they can be each used as a top-level property on their own, which is recommended. This allows for better inheritance and partial changes (e.g. changing just one value requires only one new property instead of an entire new `chef_config` mapping.
2. Attributes can be passed as a `json` or `yaml` template file, using [Jinja](http://jinja.pocoo.org/) templating. More information on this can be found under templating.
3. Chef config can be mirrored in runtime properties / attributes and any such runtime-created config will have precedence of statically defined node configurations.

### Chef Configuration and Runtime Properties

Due to Oryx2 requiring a dynamic Chef configuration, such as including a mapping with unique IDs for every instance in the system, templating and runtime properties were introduced in the modified Chef plugin. The idea is to allow nodes to reconfigure themselves or each other based on dynamically changing properties, and thus eliminate the need for manual changes that would clash with Chef's own provisioning.
 
Under the current revision of the Chef plugin, which is closely tied to this blueprint, the Chef node config (which includes the Chef attributes) is malleable at every stage of the blueprint's deployment's lifetime. Whenever the Chef plugin runs it will construct a new Chef node configuration (and consequentially new Chef attributes) based on the node and runtime properties at the time of running.
  
The chef config is constructed with the following order of precedence:

1. Runtime properties: being the most dynamic, they are use as dynamic "overrides" for default settings.
2. Properties defined at the root node property level: this eases inheritance and allows for static "overrides" of any default setings.
3. Properties defined under the common `chef_config` key: this allows for backward compatibility and for potentially isolating a "common config" which can be overwritten on a per-entry basis using top-level properties.

### Chef Templating

Whenever the Chef plugin runs, it also constructs the required Chef attributes. These can be now specified as a path to a `json` or `yaml` file, which will be loaded and templated. Using such a template introduced several advantages, the most notable being able to dynamically fine-tune any aspect of the Chef installation.

For information on how the templating works, refer to the [Jinja documentation](http://jinja.pocoo.org/docs/dev/). The base `dict` provided to the templating engine are the runtime properties, meaning an entry such as `{{ server_ip }}` will refer to the current node's `runtime_properties.server_ip` entry. Additionally the entire context is added to the templating `dict` with the `ctx` key, meaning virtually any aspect of the blueprint can be referenced.

A few examples include:
* `{{ varname }}` - references current node's `runtime_properties.varname`
* `{{ ctx.instance.runtime_properties.varname }}` - references the same variable as `{{ varname }}`
* `{{ ctx.node.properties.varname }}` - references a statically-defined property with the top-level key `varname` of the node given in the blueprint
* `{{ zookeeper_fqdns|join(',') }}` - creates a comma-delimited list entry from the node's `runtime_properties.zookeeper_fqdns` entry, which is a `list` (or any other json-serializable iterable)

A feature that would have been extremely hard to implement without the custom plugin is for example:
```
{% for fqdn in zoo_fqdns %}
    "server.{{ loop.index }}": "{{ fqdn }}:2888:3888",
{% endfor %}
```
This assigns unique IDs to FQDNs as seperate entries in a `json` Chef attributes template.

A note regarding the `ctx` entry and Chef operations during relationships - `ctx.instance` and `ctx.node` have to be references as `ctx.source.instance` (replacing `instance` with `node` and `source` with `target` where relevant).

Required Blueprint Modifications
--------------------------------

Any modifications to the Chef attributes can be done by modifying `templates/chef_attributes.json`. Almost all configuration files and other aspects of the Hadoop stack can be changed here, and should be changed here in case Chef is ever run again. Any changes to environment variables or relevant paths has to be mirrored in `resournces/compute-classpath.sh` and in the creations/configuration scripts in the `scripts` directory.

Any modifications to the Oryx2 configuration can be done by modifying `templates/oryx.conf`, `resources/compute-classpath.sh`, and modifying the creation/configuration scripts in the `scripts` directory. 

For safety reasons the key pair `hdfs.pem` and `hdfs.pem.pub` in `resources` should be recreated.

Additional parametrisation can be done by referencing properties of nodes, which can be exposed as blueprint inputs.

### Example Parametrisation: Different Worker Java Versions

Note: this is untested and as such do not mindlessly copy-paste the snippets, however follow the logic of the operations and correctly modify the blueprint.

1. Create an input representing the Java Version in the main blueprint (`draft.yaml`):

    ```yaml
    inputs:
      java_version_1:
        description: Java major version to use in the Hadoop stack (1st set of workers)
        type: integer
        default: 7
      java_version_2:
        description: Java major version to use in the Hadoop stack (2nd set of workers)
        type: integer
        default: 7
      chef_version: {}
      chef_server: {}
      chef_validation_user: {}
    ...
    ```

2. Add the `java_version` as a property to the `chef_node` definition in `node_types`:

    ```yaml
    node_types:
    ...
      chef_node:
        derived_from: cloudify.chef.nodes.ApplicationServer
        properties:
          java_version:
            description: Java major version to provision
            type: integer
            default: 7
          version:
            default: { get_input: chef_version }
          chef_server_url:
            default: { get_input: chef_server }
    ...
    ```

3. Create two different sets of `worker_stack` nodes with different `java_version` properties, and make sure to contain the different stacks on different server nodes:

    ```yaml
    node_templates:
    ...
      worker_stack_1:
        type: chef_node
        properties:
          java_version: {{ get_input: java_version_1 }}
          chef_cookbooks:
            - 'recipe[apt::default]'
            - 'recipe[java::default]'
            - 'recipe[hadoop::hadoop_hdfs_datanode]'
            - 'recipe[hadoop::hadoop_yarn_nodemanager]'
            - 'recipe[hadoop::zookeeper_server]'
            - 'recipe[hadoop::spark_worker]'
            - 'recipe[apache_kafka::default]'
        interfaces:
          cloudify.interfaces.lifecycle:
            create: 'scripts/fix_fqdn.py'
            start: 'scripts/start_worker_stack.sh'
        relationships:
          - type: cloudify.relationships.contained_in
            target: worker_1
          - type: stack_on_config
            target: config
    
      worker_stack_2:
        type: chef_node
        properties:
          java_version: {{ get_input: java_version_2 }}
          chef_cookbooks:
            - 'recipe[apt::default]'
            - 'recipe[java::default]'
            - 'recipe[hadoop::hadoop_hdfs_datanode]'
            - 'recipe[hadoop::hadoop_yarn_nodemanager]'
            - 'recipe[hadoop::zookeeper_server]'
            - 'recipe[hadoop::spark_worker]'
            - 'recipe[apache_kafka::default]'
        interfaces:
          cloudify.interfaces.lifecycle:
            create: 'scripts/fix_fqdn.py'
            start: 'scripts/start_worker_stack.sh'
        relationships:
          - type: cloudify.relationships.contained_in
            target: worker_2
          - type: stack_on_config
            target: config
    ...
    ```

4. Modify the `chef_attributes.json` template to use this new property:

    ```json
    ...
      "java": {
        "accept_license_agreement": true,
        "jdk_version": {{ ctx.node.properties.java_version }}
      },
    ...
    ```

5. Create two different sets of `worker` nodes for the different `worker_stack` nodes:

    ```yaml
    node_templates:
    ...
      worker_1:
        type: fco_instance
        instances:
          deploy: 5
      worker_2:
        type: fco_instance
        instances:
          deploy: 5
    ...
    ```

6. Fix `config` dependencies to include new `worker` nodes and `oryx` dependencies on the new `worker_stack` nodes:

    ```yaml
    node_templates:
      oryx:
        type: cloudify.nodes.ApplicationServer
        interfaces:
          cloudify.interfaces.lifecycle:
            create: 'scripts/create_oryx.sh'
            configure: 'scripts/configure_oryx.py'
            start: 'scripts/start_oryx.sh'
        relationships:
          - type: cloudify.relationships.contained_in
            target: master
          - type: oryx_on_master
            target: master_stack
          - type: cloudify.relationships.depends_on
            target: worker_stack_1
          - type: cloudify.relationships.depends_on
            target: worker_stack_2
    ...
      config:
        type: config
        interfaces:
          cloudify.interfaces.lifecycle:
            create: scripts/create_config.py
            configure: scripts/configure_config.py
        relationships:
          - type: config_in_master
            target: master
          - type: config_on_worker
            target: worker_1
          - type: config_on_worker
            target: worker_2
    ...
    ```

7. Add `java_version_1` and `java_version_2` to the inputs:

    ```yaml
    java_version_1: 7
    java_version_2: 8
    chef_version: '12.1.0-1'
    chef_server: 'https://109.231.126.168/organizations/oryx'
    chef_validation_user: 'oryx-validator'
    chef_validation_key: |
      -----BEGIN RSA PRIVATE KEY-----
     ...
     ```

The Installation Workflow
-------------------------

1. Provisioning Server instances
    * The first step is to provision the `master` server and a given number of `worker` servers. Since they have no relationships to each other this is done in parallel.
    * Although their type is currently commonly defined as `fco_instance`, they could be have been directly configured `cloudify.flexiant.nodes.Server` nodes, with separate configurations
    * The number of worker instances should be set here an not under the stack node
2. Creating the `config` node
    * As the `config` node depends on both the `master` and `worker` nodes, and other nodes depend on it, it is set up next.
    * Using a file lock on the `master` node it atomically attempts to update its runtime properties with details of the `master` and `worker` nodes
    * After all the details are collected it generates all the entries required for the other nodes in its runtime properties
3. Chef profisioning
    * As the `master_stack` and `worker_stack` have their dependencies on the `master`, `worker` and `config` nodes met, they are simultaneously set up next.
    * Before the Chef plugin is run, all the runtime properties from `config` node are copied over
    * During the Chef provisioning, runtime properties that were copied over are used to populate the template properly
    * Once the provisioning is done, final tweaks are applied and the services run
4. Oryx2 setup
    * Finally, as `oryx` depends on the `master_stack` and `worker_stack` to complete, it is set up last
    * First, relevant files are acquired
    * Secondly, templating and configuration is done
    * Finally, Oryx2 is run
    

    
