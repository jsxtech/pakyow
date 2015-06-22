module Pakyow
  module Presenter
    class ViewComposer
      class << self
        def from_path(store, path, opts = {}, &block)
          ViewComposer.new(store, path, opts, &block)
        end
      end

      extend Forwardable

      def_delegators :template, :title, :title=
      def_delegators :parts, :prop, :component

      attr_reader :store, :path, :page, :partials

      def initialize(store, path = nil, opts = {}, &block)
        @store = store
        @path = path

        self.page = opts.fetch(:page) {
          path
        }

        self.template = opts.fetch(:template) {
          (@page.is_a?(Page) && @page.info(:template)) || path
        }

        @partials = {}

        begin
          @partials = includes(opts.fetch(:includes))
        rescue
          @partials = store.partials(path) unless path.nil?
        end

        instance_exec(&block) if block_given?
      end

      def initialize_copy(original)
        super

        %w[store path page template partials view].each do |ivar|
          value = original.instance_variable_get("@#{ivar}")
          next if value.nil?

          if value.is_a?(Hash)
            dup_value = {}
            value.each_pair { |key, value| dup_value[key] = value.dup }
          else
            dup_value = value.dup
          end

          self.instance_variable_set("@#{ivar}", dup_value)
        end
      end

      def view
        build_view
      end
      alias_method :composed, :view

      def template(template = nil)
        if template.nil?
          return @template
        end

        self.template = template
        return self
      end

      def template=(template)
        unless template.is_a?(Template)
          # get template by name
          template = @store.template(template.to_sym)
        end

        @template = template

        return self
      end

      def page=(page)
        unless page.is_a?(Page)
          # get page by name
          page = @store.page(page)
        end

        @page = page

        return self
      end

      def includes(partial_map)
        @partials.merge!(remap_partials(partial_map))
      end

      def partials=(partial_map)
        @partials.merge!(remap_partials(partial_map))
      end

      def partial(name)
        partial = @partials[name]
        return partial
      end

      def container(name)
        container = @page.container(name)
        return container
      end

      def parts
        # create an array to hold the parts
        parts = ViewCollection.new

        # add the current template
        parts << @template

        # add each page container
        @page.each_container do |_, container|
          parts << container
        end

        parts.concat(partials_for_parts(parts))

        return parts
      end

      def scope(name)
        collection = parts.scope(name)

        # include partials so nested scopes/props can be bound to
        collection.each do |view|
          view.includes(partials)
        end

        #TODO make sure anytime we return a collection it tries to version
        # make this a class level helper method on ViewVersion
        if !collection.is_a?(ViewVersion) && collection.versioned?
          puts collection.class.inspect
          ViewVersion.new(collection.views)
        else
          collection
        end
      end

      private

      def build_view
        raise MissingTemplate, "No template provided to view composer" if @template.nil?
        raise MissingPage, "No page provided to view composer" if @page.nil?

        view = @template.dup.build(@page).includes(@partials)

        # set title
        title = @page.info(:title)
        view.title = title unless title.nil?

        return view
      end

      def remap_partials(partials)
        Hash[partials.map { |name, partial_or_path|
          if partial_or_path.is_a?(Partial)
            partial = partial_or_path
          else
            partial = Partial.load(@store.expand_partial_path(partial_or_path))
          end

          [name, partial]
        }]
      end

      def partials_for_parts(parts, acc = [])
        # determine the partials to be included
        available_partials = parts.inject([]) { |sum, part|
          sum.concat(part.doc.partials.keys)
        }

        # add available partials as parts
        partials.select { |name|
          available_partials.include?(name)
        }.each_pair { |_, partial|
          acc << partial
          partials_for_parts([partial], acc)
        }

        return acc
      end

    end
  end
end
