module SpreeSplitPayments
  module Generators
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, type: :boolean, default: false

      def add_javascripts
        append_file 'app/assets/javascripts/store/all.js', "//= require store/spree-split-payments\n"
        append_file 'app/assets/javascripts/admin/all.js', "//= require admin/spree-split-payments\n"
      end

      def add_stylesheets
        inject_into_file 'app/assets/stylesheets/store/all.css', " *= require store/spree-split-payments\n", before: /\*\//, verbose: true
        inject_into_file 'app/assets/stylesheets/admin/all.css', " *= require admin/spree-split-payments\n", before: /\*\//, verbose: true
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_split_payments'
      end

      def run_migrations
        run 'bundle exec rake db:migrate'
      end
    end
  end
end
