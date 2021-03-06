# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # This cop checks presence of parentheses in method calls containing
      # parameters. By default, macro methods are ignored. Additional methods
      # can be added to the `IgnoredMethods` list.
      #
      # @example
      #
      #   # bad
      #   array.delete e
      #
      #   # good
      #   array.delete(e)
      #
      #   # okay with `puts` listed in `IgnoredMethods`
      #   puts 'test'
      #
      #   # IgnoreMacros: true (default)
      #
      #   # good
      #   class Foo
      #     bar :baz
      #   end
      #
      #   # IgnoreMacros: false
      #
      #   # bad
      #   class Foo
      #     bar :baz
      #   end
      class MethodCallWithArgsParentheses < Cop
        MSG = 'Use parentheses for method calls with arguments.'.freeze

        def on_send(node)
          return if ignored_list.include?(node.method_name)
          return unless node.arguments? && !node.parenthesized?
          return if operator_call?(node)
          return if ignore_macros? && node.macro?

          add_offense(node, :selector)
        end

        def on_super(node)
          # super nodetype implies call with arguments.
          return if parentheses?(node)

          add_offense(node, :keyword)
        end

        def on_yield(node)
          args = node.children
          return if args.empty?
          return if parentheses?(node)

          add_offense(node, :keyword)
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(args_begin(node), '(')
            corrector.insert_after(args_end(node), ')')
          end
        end

        private

        def ignored_list
          cop_config['IgnoredMethods'].map(&:to_sym)
        end

        def ignore_macros?
          cop_config['IgnoreMacros']
        end

        def parentheses?(node)
          node.loc.begin
        end

        def operator_call?(node)
          node.operator_method?
        end

        def args_begin(node)
          loc = node.loc
          selector = node.super_type? ? loc.keyword : loc.selector
          selector.end.resize(1)
        end

        def args_end(node)
          node.loc.expression.end
        end
      end
    end
  end
end
