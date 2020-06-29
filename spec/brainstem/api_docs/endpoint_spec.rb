require 'spec_helper'
require 'brainstem/api_docs/endpoint'

module Brainstem
  module ApiDocs
    describe Endpoint do
      let(:lorem) { "lorem ipsum dolor sit amet" }
      let(:atlas) { Object.new }
      let(:options) { { include_internal: internal_flag } }
      let(:internal_flag) { false }
      subject { described_class.new(atlas, options) }

      describe "#initialize" do
        it "yields self if given a block" do
          block = Proc.new { |s| s.path = "bork bork" }
          expect(described_class.new(atlas, &block).path).to eq "bork bork"
        end
      end

      describe "#merge_http_methods!" do
        before do
          options[:http_methods] = %w(GET)
        end

        it "adds http methods that are not already present" do

          expect(subject.http_methods).to eq %w(GET)
          subject.merge_http_methods!(%w(POST PATCH GET))
          expect(subject.http_methods).to eq %w(GET POST PATCH)
        end
      end

      describe "configured fields" do
        let(:const) do
          Class.new do
            def self.brainstem_model_name
              :widget
            end
          end
        end

        let(:controller) { Object.new }
        let(:action) { :show }

        let(:lorem) { "lorem ipsum dolor sit amet" }
        let(:default_config) { {} }
        let(:show_config) { {} }
        let(:create_config) { {} }
        let(:nodoc) { false }
        let(:internal) { false }

        let(:configuration) {
          {
            :_default => default_config,
            :show => show_config,
            :create => create_config
          }
        }

        before do
          stub(controller).configuration { configuration }
          stub(controller).const { const }
          options[:controller] = controller
          options[:action] = action
        end

        describe "#nodoc?" do
          let(:show_config) { { nodoc: nodoc, internal: internal } }

          context "when nodoc" do
            let(:nodoc) { true }

            it "is true" do
              expect(subject.nodoc?).to eq true
            end
          end

          context "when internal flag is true" do
            let(:internal_flag) { true }

            context "when action config is internal" do
              let(:internal) { true }

              it "is false" do
                expect(subject.nodoc?).to eq false
              end
            end

            context "when action config is not internal" do
              let(:internal) { false }

              it "is false" do
                expect(subject.nodoc?).to eq false
              end
            end
          end

          context "when internal flag is false" do
            let(:internal_flag) { false }

            context "when action config is internal" do
              let(:internal) { true }

              it "is true" do
                expect(subject.nodoc?).to eq true
              end
            end

            context "when action config is not internal" do
              let(:internal) { false }

              it "is false" do
                expect(subject.nodoc?).to eq false
              end
            end
          end

          context "when documentable" do
            it "is false" do
              expect(subject.nodoc?).to eq false
            end
          end
        end

        describe "#title" do
          context "when present" do
            let(:show_config) { { title: { info: lorem, nodoc: nodoc, internal: internal } } }

            context "when nodoc" do
              let(:nodoc) { true }

              it "uses the action name" do
                expect(subject.title).to eq "Show"
              end
            end

            context "when documentable" do
              it "formats the title as an h4" do
                expect(subject.title).to eq lorem
              end
            end

            context "when internal flag is true" do
              let(:internal_flag) { true }

              context "when title is internal" do
                let(:internal) { true }

                it "formats the title as an h4" do
                  expect(subject.title).to eq lorem
                end
              end

              context "when title is not internal" do
                let(:internal) { false }

                it "formats the title as an h4" do
                  expect(subject.title).to eq lorem
                end
              end
            end

            context "when internal flag is false" do
              let(:internal_flag) { false }

              context "when title is internal" do
                let(:internal) { true }

                it "uses the action name" do
                  expect(subject.title).to eq "Show"
                end
              end

              context "when title is not internal" do
                let(:internal) { false }

                it "formats the title as an h4" do
                  expect(subject.title).to eq lorem
                end
              end
            end
          end

          context "when absent" do
            it "falls back to the action name" do
              expect(subject.title).to eq "Show"
            end
          end
        end

        describe "#description" do
          context "when present" do
            let(:show_config) { { description: { info: lorem, nodoc: nodoc, internal: internal } } }

            context "when nodoc" do
              let(:nodoc) { true }

              it "shows nothing" do
                expect(subject.description).to be_empty
              end
            end

            context "when not nodoc" do
              it "shows the description" do
                expect(subject.description).to eq lorem
              end
            end

            context "when internal flag is true" do
              let(:internal_flag) { true }

              context "when description is internal" do
                let(:internal) { true }

                it "shows the description" do
                  expect(subject.description).to eq lorem
                end
              end

              context "when description is not internal" do
                let(:internal) { false }

                it "shows the description" do
                  expect(subject.description).to eq lorem
                end
              end
            end

            context "when internal flag is false" do
              let(:internal_flag) { false }

              context "when description is internal" do
                let(:internal) { true }

                it "shows nothing" do
                  expect(subject.description).to be_empty
                end
              end

              context "when description is not internal" do
                let(:internal) { false }

                it "shows the description" do
                  expect(subject.description).to eq lorem
                end
              end
            end
          end

          context "when not present" do
            it "shows nothing" do
              expect(subject.description).to be_empty
            end
          end
        end

        describe "#bulk_create" do
          let(:action) { :create }

          context "when present" do
            let(:details) { { limit: 100, name: :creators } }
            let(:create_config) { { bulk_create_details: details } }

            it "returns the details" do
              expect(subject.bulk_create).to eq(details)
            end
          end

          context "when not present" do
            let(:create_config) { { title: "Create Stuff" } }

            it "returns an empty hash" do
              expect(subject.bulk_create).to be_nil
            end
          end
        end

        describe "#valid_params" do
          it "returns the valid_params key from action or default" do
            mock(subject).key_with_default_fallback(:valid_params)
            subject.valid_params
          end
        end

        describe "#operation_id" do
          context "when present" do
            let(:show_config) { { operation_id: "blah" } }

            it "returns the operation ID" do
              expect(subject.operation_id).to eq("blah")
            end
          end

          context "when not present" do
            let(:show_config) { { title: "Blah" } }

            it "returns nothing" do
              expect(subject.operation_id).to be_nil
            end
          end
        end

        describe "#produces" do
          it "returns the produces key from action or default" do
            mock(subject).key_with_default_fallback(:produces)
            subject.produces
          end
        end

        describe "#consumes" do
          it "returns the consumes key from action or default" do
            mock(subject).key_with_default_fallback(:consumes)
            subject.consumes
          end
        end

        describe "#security" do
          it "returns the security key from action or default" do
            mock(subject).key_with_default_fallback(:security)
            subject.security
          end
        end

        describe "#schemes" do
          it "returns the schemes key from action or default" do
            mock(subject).key_with_default_fallback(:schemes)
            subject.schemes
          end
        end

        describe "#external_docs" do
          it "returns the external_docs key from action or default" do
            mock(subject).key_with_default_fallback(:external_docs)
            subject.external_docs
          end
        end

        describe "#deprecated" do
          it "returns the deprecated key from action or default" do
            mock(subject).key_with_default_fallback(:deprecated)
            subject.deprecated
          end
        end

        describe "#response_details" do
          context "when present" do
            let(:details) { { object_name: 'Blah', response_type: 'single' } }
            let(:show_config) { { response_details: details } }

            it "returns the details" do
              expect(subject.response_details).to eq(details)
            end
          end

          context "when not present" do
            let(:show_config) { { title: "Blah" } }

            it "returns an empty hash" do
              expect(subject.response_details).to eq({})
            end
          end
        end

        describe "#params_configuration_tree" do
          let(:action) { :create }
          let(:root_fields_config) { {} }
          let(:bulk_create_config) { {} }
          let(:create_config) do
            {
              valid_params: create_params,
              root_fields: root_fields_config,
              bulk_create_details: bulk_create_config,
            }.reject { |_, v| v.blank? }
          end

          context "non-nested params" do
            let(:root_param) { { Proc.new { 'title' } => { nodoc: nodoc, type: 'string', internal: internal } } }
            let(:create_params) { root_param }

            context "when nodoc" do
              let(:nodoc) { true }

              it "rejects the key" do
                expect(subject.params_configuration_tree).to be_empty
              end
            end

            context "when not nodoc" do
              let(:nodoc) { false }

              it "lists it as a root param" do
                expect(subject.params_configuration_tree).to eq(
                  {
                    title: {
                      _config: { type: 'string' }
                    }
                  }.with_indifferent_access
                )
              end

              context "when param has an item" do
                let(:create_params) { { widget_ids: { nodoc: nodoc, type: 'array', item: 'integer' } } }

                it "lists it as a root param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      widget_ids: {
                        _config: { type: 'array', item: 'integer' }
                      }
                    }.with_indifferent_access
                  )
                end
              end
            end

            context "when internal flag is true" do
              let(:internal_flag) { true }

              context "when params_configuration_tree is internal" do
                let(:internal) { true }

                it "lists it as a root param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      title: {
                        _config: { type: 'string' }
                      }
                    }.with_indifferent_access
                  )
                end
              end

              context "when params_configuration_tree is not internal" do
                let(:internal) { false }

                it "lists it as a root param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      title: {
                        _config: { type: 'string' }
                      }
                    }.with_indifferent_access
                  )
                end
              end
            end

            context "when internal flag is false" do
              let(:internal_flag) { false }

              context "when description is internal" do
                let(:internal) { true }

                it "rejects the key" do
                  expect(subject.params_configuration_tree).to be_empty
                end
              end

              context "when description is not internal" do
                let(:internal) { false }

                it "lists it as a root param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      title: {
                        _config: { type: 'string' }
                      }
                    }.with_indifferent_access
                  )
                end
              end
            end
          end

          context "nested params" do
            let(:root_name_proc) { Proc.new { 'sprocket' } }
            let(:root_proc) { Proc.new { root_name_proc.call.to_s } }
            let(:root_fields_config) { { single: { name: root_name_proc, config: { 'type' => 'hash' } } } }
            let(:nested_param) {
              { Proc.new { 'title' } => {
                nodoc: nodoc,
                type: 'string',
                root: root_proc,
                ancestors: [root_proc],
                internal: internal
              } }
            }
            let(:create_params) { nested_param }

            context "when nodoc" do
              let(:nodoc) { true }

              it "rejects the key" do
                expect(subject.params_configuration_tree).to be_empty
              end
            end

            context "when internal flag is true" do
              let(:internal_flag) { true }

              context "when params_configuration_tree is internal" do
                let(:internal) { true }

                it "lists it as a nested param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      sprocket: {
                        _config: {
                          type: 'hash',
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        }
                      }
                    }.with_indifferent_access
                  )
                end
              end

              context "when params_configuration_tree is not internal" do
                let(:internal) { false }

                it "lists it as a nested param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      sprocket: {
                        _config: {
                          type: 'hash',
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        }
                      }
                    }.with_indifferent_access
                  )
                end
              end
            end

            context "when internal flag is false" do
              let(:internal_flag) { false }

              context "when description is internal" do
                let(:internal) { true }

                it "rejects the key" do
                  expect(subject.params_configuration_tree).to be_empty
                end
              end

              context "when description is not internal" do
                let(:internal) { false }

                it "lists it as a nested param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      sprocket: {
                        _config: {
                          type: 'hash',
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        }
                      }
                    }.with_indifferent_access
                  )
                end
              end
            end

            context "when not nodoc" do
              it "lists it as a nested param" do
                expect(subject.params_configuration_tree).to eq(
                  {
                    sprocket: {
                      _config: {
                        type: 'hash',
                      },
                      title: {
                        _config: {
                          type: 'string'
                        }
                      }
                    }
                  }.with_indifferent_access
                )
              end

              context "when nested param has an item" do
                let(:create_params) {
                  {
                    Proc.new { 'ids' } => { nodoc: nodoc, type: 'array', item: 'integer', root: root_proc, ancestors: [root_proc] }
                  }
                }

                it "lists it as a nested param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      sprocket: {
                        _config: {
                          type: 'hash'
                        },
                        ids: {
                          _config: {
                            type: 'array',
                            item: 'integer'
                          }
                        }
                      }
                    }.with_indifferent_access
                  )
                end
              end

              context "when the root params supports bulk operation" do
                let(:root_name_proc) { Proc.new { 'sprocket' } }
                let(:bulk_root_name_proc) { Proc.new {  'sprockets' } }
                let(:root_proc) do
                  Proc.new { |_, is_bulk| (is_bulk ? bulk_root_name_proc : root_name_proc).call.to_s }
                end
                let(:root_fields_config) {
                  {
                    single: { name: root_name_proc, config: { 'type' => 'hash' } },
                    bulk: { name: root_name_proc, config: { 'type' => 'array', item_type: 'hash' } },
                  }
                }
                let(:bulk_create_config) { { name: bulk_root_name_proc, limit: 100 } }

                it "lists the nested params as single and bulk param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      sprocket: {
                        _config: {
                          type: 'hash',
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        }
                      },
                      sprockets: {
                        _config: {
                          type: 'array',
                          item_type: 'hash'
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        }
                      }
                    }.with_indifferent_access
                  )
                end
              end
            end
          end

          context "proc nested params" do
            let(:root_name_proc) { Proc.new { |klass| klass.brainstem_model_name } }
            let(:root_proc) { Proc.new { |klass| root_name_proc.call(klass).to_s } }
            let(:root_fields_config) { { single: { name: root_name_proc, config: { 'type' => 'hash' } } } }
            let(:proc_nested_param) {
              { Proc.new { 'title' } => { nodoc: nodoc, type: 'string', root: root_proc, ancestors: [root_proc] } }
            }
            let(:create_params) { proc_nested_param }

            context "when nodoc" do
              let(:nodoc) { true }

              it "rejects the key" do
                expect(subject.params_configuration_tree).to be_empty
              end
            end

            context "when not nodoc" do
              it "evaluates the proc in the controller's context and lists it as a nested param" do
                mock.proxy(const).brainstem_model_name.at_least(1)

                result = subject.params_configuration_tree
                expect(result.keys).to eq(%w(widget))

                children_of_the_root = result[:widget].except(:_config)
                expect(children_of_the_root.keys).to eq(%w(title))

                title_param = children_of_the_root[:title][:_config]
                expect(title_param.keys).to eq(%w(type))
                expect(title_param[:type]).to eq('string')
              end

              context "when root param supports bulk operation" do
                let(:bulk_root_name_proc) { Proc.new { |klass| klass.brainstem_model_name.to_s.pluralize } }
                let(:root_proc) do
                  Proc.new do |klass, is_bulk|
                    (is_bulk ? bulk_root_name_proc : root_name_proc).call(klass).to_s
                  end
                end
                let(:root_fields_config) {
                  {
                    single: { name: root_name_proc, config: { 'type' => 'hash' } },
                    bulk: { name: bulk_root_name_proc, config: { 'type' => 'array', item_type: 'hash' } },
                  }
                }
                let(:bulk_create_config) { { name: bulk_root_name_proc, limit: 100 } }

                it "evaluates the proc in the controller's context and lists it as a nested param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      widget: {
                        _config: {
                          type: 'hash',
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        }
                      },
                      widgets: {
                        _config: {
                          type: 'array',
                          item_type: 'hash'
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        }
                      }
                    }.with_indifferent_access
                  )
                end
              end
            end
          end

          context "multi nested params" do
            let(:project_name_proc) { Proc.new { 'project' } }
            let(:project_proc) { Proc.new { |klass| project_name_proc.call(klass).to_s } }
            let(:root_fields_config) { { single: { name: project_proc, config: { 'type' => 'hash' } } } }
            let(:id_proc) { Proc.new { 'id' } }
            let(:task_proc) { Proc.new { 'task' } }
            let(:title_proc) { Proc.new { 'title' } }
            let(:checklist_proc) { Proc.new { 'checklist' } }
            let(:name_proc) { Proc.new { 'name' } }

            context "has a root & ancestors" do
              let(:create_params) {
                {
                  id_proc => {
                    type: 'integer'
                  },
                  task_proc => {
                    type: 'hash',
                    root: project_proc,
                    ancestors: [project_proc]
                  },
                  title_proc => {
                    type: 'string',
                    ancestors: [project_proc, task_proc]
                  },
                  checklist_proc => {
                    type: 'array',
                    item: 'hash',
                    ancestors: [project_proc, task_proc]
                  },
                  name_proc => {
                    type: 'string',
                    ancestors: [project_proc, task_proc, checklist_proc]
                  }
                }
              }

              context "when a leaf param has no doc" do
                before do
                  create_params[name_proc][:nodoc] = true
                end

                it "rejects the key" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      id: {
                        _config: {
                          type: 'integer',
                        }
                      },
                      project: {
                        _config: {
                          type: 'hash',
                        },
                        task: {
                          _config: {
                            type: 'hash',
                          },
                          title: {
                            _config: {
                              type: 'string'
                            }
                          },
                          checklist: {
                            _config: {
                              type: 'array',
                              item: 'hash',
                            }
                          },
                        },
                      },
                    }.with_indifferent_access
                  )
                end
              end

              context "when nodoc on a parent param" do
                before do
                  create_params[checklist_proc][:nodoc] = true
                  create_params[name_proc][:nodoc] = true # This will be inherited from the parent when the param is defined.
                end

                it "rejects the parent key and its children" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      id: {
                        _config: {
                          type: 'integer'
                        }
                      },
                      project: {
                        _config: {
                          type: 'hash'
                        },
                        task: {
                          _config: {
                            type: 'hash',
                          },
                          title: {
                            _config: {
                              type: 'string'
                            }
                          },
                        },
                      },
                    }.with_indifferent_access
                  )
                end
              end

              context "when not nodoc" do
                it "evaluates the proc in the controller's context and lists it as a nested param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      id: {
                        _config: {
                          type: 'integer'
                        }
                      },
                      project: {
                        _config: {
                          type: 'hash',
                        },
                        task: {
                          _config: {
                            type: 'hash',
                          },
                          title: {
                            _config: {
                              type: 'string'
                            }
                          },
                          checklist: {
                            _config: {
                              type: 'array',
                              item: 'hash'
                            },
                            name: {
                              _config: {
                                type: 'string'
                              }
                            },
                          },
                        },
                      },
                    }.with_indifferent_access
                  )
                end

                context "when root param supports bulk operation" do
                  let(:bulk_project_name_proc) { Proc.new {  'projects' } }
                  let(:project_proc) do
                    Proc.new { |_, is_bulk| (is_bulk ? bulk_project_name_proc : project_name_proc).call.to_s }
                  end
                  let(:root_fields_config) {
                    {
                      single: { name: project_name_proc, config: { 'type' => 'hash' } },
                      bulk: { name: bulk_project_name_proc, config: { 'type' => 'array', item_type: 'hash' } },
                    }
                  }
                  let(:bulk_create_config) { { name: bulk_project_name_proc, limit: 100 } }

                  it "evaluates the proc in the controller's context and lists it as a nested param" do
                    expect(subject.params_configuration_tree).to eq(
                      {
                        id: {
                          _config: {
                            type: 'integer'
                          }
                        },
                        project: {
                          _config: {
                            type: 'hash',
                          },
                          task: {
                            _config: {
                              type: 'hash',
                            },
                            title: {
                              _config: {
                                type: 'string'
                              }
                            },
                            checklist: {
                              _config: {
                                type: 'array',
                                item: 'hash'
                              },
                              name: {
                                _config: {
                                  type: 'string'
                                }
                              },
                            },
                          },
                        },
                        projects: {
                          _config: {
                            type: 'array',
                            item_type: 'hash',
                          },
                          task: {
                            _config: {
                              type: 'hash',
                            },
                            title: {
                              _config: {
                                type: 'string'
                              }
                            },
                            checklist: {
                              _config: {
                                type: 'array',
                                item: 'hash'
                              },
                              name: {
                                _config: {
                                  type: 'string'
                                }
                              },
                            },
                          },
                        },
                      }.with_indifferent_access
                    )
                  end
                end
              end
            end

            context "has only ancestors" do
              let(:create_params) {
                {
                  task_proc => {
                    type: 'hash',
                  },
                  title_proc => {
                    type: 'string',
                    ancestors: [task_proc]
                  },
                  checklist_proc => {
                    type: 'array',
                    item: 'hash',
                    ancestors: [task_proc]
                  },
                  name_proc => {
                    type: 'string',
                    ancestors: [task_proc, checklist_proc]
                  }
                }
              }

              context "when a leaf param has no doc" do
                before do
                  create_params[name_proc][:nodoc] = true
                end

                it "rejects the key" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      task: {
                        _config: {
                          type: 'hash'
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        },
                        checklist: {
                          _config: {
                            type: 'array',
                            item: 'hash'
                          }
                        },
                      },
                    }.with_indifferent_access
                  )
                end
              end

              context "when parent param has nodoc" do
                before do
                  create_params[checklist_proc][:nodoc] = true
                  create_params[name_proc][:nodoc] = true # This will be inherited from the parent when the param is defined.
                end

                it "rejects the parent key and its children" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      task: {
                        _config: {
                          type: 'hash'
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        }
                      }
                    }.with_indifferent_access
                  )
                end
              end

              context "when not nodoc" do
                it "evaluates the proc in the controller's context and lists it as a nested param" do
                  expect(subject.params_configuration_tree).to eq(
                    {
                      task: {
                        _config: {
                          type: 'hash'
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        },
                        checklist: {
                          _config: {
                            type: 'array',
                            item: 'hash',
                          },
                          name: {
                            _config: {
                              type: 'string',
                            }
                          },
                        },
                      },
                    }.with_indifferent_access
                  )
                end
              end
            end
          end
        end

        describe "#valid_presents" do
          it "returns the presents key from action or default" do
            mock(subject).key_with_default_fallback(:presents)
            subject.valid_presents
          end
        end

        describe "#contextual_documentation" do
          let(:show_config) { { title: { info: info, nodoc: nodoc, internal: internal } } }
          let(:info) { lorem }

          context "when has the key" do
            let(:key) { :title }

            context "when internal flag is true" do
              let(:internal_flag) { true }

              context "when contextual key is internal" do
                let(:internal) { true }

                it "is the info" do
                  expect(subject.contextual_documentation(key)).to eq lorem
                end
              end

              context "when contextual key is not internal" do
                let(:internal) { false }

                it "is the info" do
                  expect(subject.contextual_documentation(key)).to eq lorem
                end
              end
            end

            context "when internal flag is false" do
              let(:internal_flag) { false }

              context "when contextual key is internal" do
                let(:internal) { true }

                it "is falsey" do
                  expect(subject.contextual_documentation(key)).to be_falsey
                end
              end

              context "when contextual key is not internal" do
                let(:internal) { false }

                it "is the info" do
                  expect(subject.contextual_documentation(key)).to eq lorem
                end
              end
            end

            context "when not nodoc" do
              context "when has info" do
                it "is truthy" do
                  expect(subject.contextual_documentation(key)).to be_truthy
                end

                it "is the info" do
                  expect(subject.contextual_documentation(key)).to eq lorem
                end
              end

              context "when has no info" do
                let(:info) { nil }

                it "is falsey" do
                  expect(subject.contextual_documentation(key)).to be_falsey
                end
              end
            end

            context "when nodoc" do
              let(:nodoc) { true }

              it "is falsey" do
                expect(subject.contextual_documentation(key)).to be_falsey
              end
            end
          end

          context "when doesn't have the key" do
            let(:key) { :herp }

            it "is falsey" do
              expect(subject.contextual_documentation(key)).to be_falsey
            end
          end
        end

        describe "#key_with_default_fallback" do
          let(:default_config) { { info: "default" } }

          context "when it has the key in the action config" do
            let(:show_config) { { info: "show" } }

            it "returns that" do
              expect(subject.key_with_default_fallback(:info)).to eq "show"
            end
          end

          context "when it has the key only in the default config" do
            it "returns that" do
              expect(subject.key_with_default_fallback(:info)).to eq "default"
            end
          end
        end
      end

      describe "#sort" do
        actions = %w(index show create update delete articuno zapdos moltres)

        actions.each do |axn|
          let(axn.to_sym) { described_class.new(atlas, action: axn.to_sym) }
        end

        let(:axns) { actions.map { |axn| send(axn.to_sym) } }

        it "orders appropriately" do
          sorted = axns.reverse.sort
          expect(sorted[0]).to eq index
          expect(sorted[1]).to eq show
          expect(sorted[2]).to eq create
          expect(sorted[3]).to eq update
          expect(sorted[4]).to eq delete
          expect(sorted[5]).to eq articuno
          expect(sorted[6]).to eq moltres
          expect(sorted[7]).to eq zapdos
        end
      end

      describe "#presenter_title" do
        let(:presenter) { mock!.title.returns(lorem).subject }
        let(:options) { { presenter: presenter } }

        it "returns the presenter's title" do
          expect(subject.presenter_title).to eq lorem
        end
      end

      describe "#relative_presenter_path_from_controller" do
        let(:presenter) {
          mock!
            .suggested_filename_link(:markdown)
            .returns("objects/sprocket_widget")
            .subject
        }

        let(:controller) {
          mock!
            .suggested_filename_link(:markdown)
            .returns("controllers/api/v1/sprocket_widgets_controller")
            .subject
        }

        let(:options) { { presenter: presenter, controller: controller } }

        it "returns a relative path" do
          expect(subject.relative_presenter_path_from_controller(:markdown)).to \
            eq "../../../objects/sprocket_widget"
        end
      end

      describe "custom response" do
        let(:const) do
          Class.new do
            def self.brainstem_model_name
              :widget
            end
          end
        end

        let(:controller) { Object.new }
        let(:action) { :show }
        let(:show_config) { {} }
        let(:nodoc) { false }
        let(:configuration) { { :show => show_config } }

        before do
          options[:controller] = controller
          options[:action] = action
          stub(controller).configuration { configuration }
          stub(controller).const { const }
        end

        describe "#custom_response_configuration_tree" do
          let(:default_response_config) { { nodoc: nodoc, type: 'array', item_type: 'hash' } }

          context "when no custom response is present" do
            let(:show_config) { {} }

            it "returns empty object" do
              expect(subject.custom_response_configuration_tree).to be_empty
            end
          end

          context "when custom response is present" do
            let(:show_config) do
              {
                custom_response: { _config: default_response_config }.merge(other_response_fields)
              }
            end

            context "non-nested params" do
              let(:other_response_fields) do
                { Proc.new { 'title' } => { nodoc: nodoc, type: 'string' } }
              end

              context "when nodoc" do
                let(:nodoc) { true }

                it "rejects the key" do
                  expect(subject.custom_response_configuration_tree).to eq(
                    {
                      _config: default_response_config
                    }.with_indifferent_access
                  )
                end
              end

              context "when not nodoc" do
                let(:nodoc) { false }

                it "lists it as a root param" do
                  expect(subject.custom_response_configuration_tree).to eq(
                    {
                      _config: default_response_config,
                      title: {
                        _config: { type: 'string' }
                      }
                    }.with_indifferent_access
                  )
                end

                context "when param has an item" do
                  let(:other_response_fields) do
                    { Proc.new { 'only' } => { nodoc: nodoc, type: 'array', item: 'integer' } }
                  end

                  it "lists it as a root param" do
                    expect(subject.custom_response_configuration_tree).to eq(
                      {
                        _config: default_response_config,
                        only: {
                          _config: { type: 'array', item: 'integer' }
                        }
                      }.with_indifferent_access
                    )
                  end
                end
              end
            end

            context "nested params" do
              let(:internal) { false }
              let(:parent_proc) { Proc.new { 'sprocket' } }
              let(:other_response_fields) do
                {
                  parent_proc => {
                    nodoc: nodoc,
                    type: 'array',
                    item_type: 'hash',
                    internal: internal
                  },
                  Proc.new { 'title' } => {
                    nodoc: nodoc,
                    type: 'string',
                    ancestors: [parent_proc],
                    internal: internal
                  },
                  Proc.new { 'nested_array' } => {
                    nodoc: nodoc,
                    type: 'array',
                    item_type: 'string',
                    nested_levels: 2,
                    ancestors: [parent_proc],
                    internal: internal
                  },
                }
              end

              context "when nodoc" do
                let(:nodoc) { true }

                it "rejects the key" do
                  expect(subject.custom_response_configuration_tree).to eq(
                    {
                      _config: default_response_config,
                    }.with_indifferent_access
                  )
                end
              end

              context "when internal flag is true" do
                let(:internal_flag) { true }

                context "when tree is internal" do
                  let(:internal) { true }

                  it "lists it as a nested param" do
                    expect(subject.custom_response_configuration_tree).to eq(
                      {
                        _config: default_response_config,
                        sprocket: {
                          _config: {
                            type: 'array',
                            item_type: 'hash'
                          },
                          title: {
                            _config: {
                              type: 'string'
                            }
                          },
                          nested_array: {
                            _config: {
                              type: 'array',
                              nested_levels: 2,
                              item_type: 'string'
                            }
                          }
                        }
                      }.with_indifferent_access
                    )
                  end
                end

                context "when params_configuration_tree is not internal" do
                  let(:internal) { false }

                  it "lists it as a nested param" do
                    expect(subject.custom_response_configuration_tree).to eq(
                      {
                        _config: default_response_config,
                        sprocket: {
                          _config: {
                            type: 'array',
                            item_type: 'hash'
                          },
                          title: {
                            _config: {
                              type: 'string'
                            }
                          },
                          nested_array: {
                            _config: {
                              type: 'array',
                              nested_levels: 2,
                              item_type: 'string'
                            }
                          }
                        }
                      }.with_indifferent_access
                    )
                  end
                end
              end

              context "when internal flag is false" do
                let(:internal_flag) { false }

                context "when description is internal" do
                  let(:internal) { true }

                  it "rejects the key" do
                    expect(subject.params_configuration_tree).to be_empty
                  end
                end

                context "when description is not internal" do
                  let(:internal) { false }

                  it "lists it as a nested param" do
                    expect(subject.custom_response_configuration_tree).to eq(
                      {
                        _config: default_response_config,
                        sprocket: {
                          _config: {
                            type: 'array',
                            item_type: 'hash'
                          },
                          title: {
                            _config: {
                              type: 'string'
                            }
                          },
                          nested_array: {
                            _config: {
                              type: 'array',
                              nested_levels: 2,
                              item_type: 'string'
                            }
                          }
                        }
                      }.with_indifferent_access
                    )
                  end
                end
              end

              context "when not nodoc" do
                it "lists it as a nested param" do
                  expect(subject.custom_response_configuration_tree).to eq(
                    {
                      _config: default_response_config,
                      sprocket: {
                        _config: {
                          type: 'array',
                          item_type: 'hash'
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        },
                        nested_array: {
                          _config: {
                            type: 'array',
                            nested_levels: 2,
                            item_type: 'string'
                          }
                        }
                      }
                    }.with_indifferent_access
                  )
                end

                context "when nested param has an item" do
                  let(:other_response_fields) do
                    {
                      parent_proc => { nodoc: nodoc, type: 'array', item_type: 'hash' },
                      Proc.new { 'ids' } => { nodoc: nodoc, type: 'array', item: 'integer', ancestors: [parent_proc] }
                    }
                  end

                  it "lists it as a nested param" do
                    expect(subject.custom_response_configuration_tree).to eq(
                      {
                        _config: default_response_config,
                        sprocket: {
                          _config: {
                            type: 'array',
                            item_type: 'hash'
                          },
                          ids: {
                            _config: {
                              type: 'array',
                              item: 'integer'
                            }
                          }
                        }
                      }.with_indifferent_access
                    )
                  end
                end
              end
            end

            context "multi nested params" do
              let(:project_proc) { Proc.new { 'project' } }
              let(:id_proc) { Proc.new { 'id' } }
              let(:task_proc) { Proc.new { 'task' } }
              let(:title_proc) { Proc.new { 'title' } }
              let(:checklist_proc) { Proc.new { 'checklist' } }
              let(:name_proc) { Proc.new { 'name' } }
              let(:other_response_fields) do
                {
                  task_proc => {
                    type: 'hash',
                  },
                  title_proc => {
                    type: 'string',
                    ancestors: [task_proc]
                  },
                  checklist_proc => {
                    type: 'array',
                    item: 'hash',
                    ancestors: [task_proc]
                  },
                  name_proc => {
                    type: 'string',
                    ancestors: [task_proc, checklist_proc]
                  }
                }
              end

              context "when a leaf param has no doc" do
                before do
                  other_response_fields[name_proc][:nodoc] = true
                end

                it "rejects the key" do
                  expect(subject.custom_response_configuration_tree).to eq(
                    {
                      _config: default_response_config,
                      task: {
                        _config: {
                          type: 'hash'
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        },
                        checklist: {
                          _config: {
                            type: 'array',
                            item: 'hash'
                          }
                        },
                      },
                    }.with_indifferent_access
                  )
                end
              end

              context "when parent param has nodoc" do
                before do
                  other_response_fields[checklist_proc][:nodoc] = true
                  # The nested field will be inherit the nodoc property from its parent.
                  other_response_fields[name_proc][:nodoc] = true
                end

                it "rejects the parent key and its children" do
                  expect(subject.custom_response_configuration_tree).to eq(
                    {
                      _config: default_response_config,
                      task: {
                        _config: {
                          type: 'hash'
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        }
                      }
                    }.with_indifferent_access
                  )
                end
              end

              context "when not nodoc" do
                it "evaluates the proc in the controller's context and lists it as a nested param" do
                  expect(subject.custom_response_configuration_tree).to eq(
                    {
                      _config: default_response_config,
                      task: {
                        _config: {
                          type: 'hash'
                        },
                        title: {
                          _config: {
                            type: 'string'
                          }
                        },
                        checklist: {
                          _config: {
                            type: 'array',
                            item: 'hash',
                          },
                          name: {
                            _config: {
                              type: 'string',
                            }
                          },
                        },
                      },
                    }.with_indifferent_access
                  )
                end
              end
            end
          end
        end
      end

      it_behaves_like "formattable"
      it_behaves_like "atlas taker"
    end
  end
end
