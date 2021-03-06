fiftyfive_recipe :rbenv do
  during :provision, %w(install write_vars)
end

namespace :fiftyfive do
  namespace :rbenv do
    desc "Install rbenv and compile ruby"
    task :install do
      invoke "fiftyfive:rbenv:run_installer"
      invoke "fiftyfive:rbenv:modify_bashrc"
      invoke "fiftyfive:rbenv:bootstrap_ubuntu_for_ruby_compile"
      invoke "fiftyfive:rbenv:compile_ruby"
    end

    desc "Install the latest version of Ruby"
    task :upgrade do
      invoke "fiftyfive:rbenv:update_rbenv"
      invoke "fiftyfive:rbenv:bootstrap_ubuntu_for_ruby_compile"
      invoke "fiftyfive:rbenv:compile_ruby"
    end

    task :write_vars do
      on release_roles(:all) do
        execute :mkdir, "-p ~/.rbenv"
        execute :touch, "~/.rbenv/vars"
        execute :chmod, "0600 ~/.rbenv/vars"

        vars = ""

        fetch(:fiftyfive_rbenv_vars).each do |name, value|
          execute :sed, "--in-place '/^#{name}=/d' ~/.rbenv/vars"
          vars << "#{name}=#{value}\n"
        end

        tmp_file = "/tmp/rbenv_vars"
        put vars, tmp_file
        execute :cat, tmp_file, ">> ~/.rbenv/vars"
        execute :rm, tmp_file
      end
    end

    task :run_installer do
      on release_roles(:all) do
        execute :curl,
                "-L https://raw.github.com/fesplugas/rbenv-installer/master/bin/rbenv-installer",
                "|", :bash
      end
    end

    task :modify_bashrc do
      on release_roles(:all) do
        unless test("grep -qs 'rbenv init' ~/.bashrc")
          template("rbenv_bashrc", "/tmp/rbenvrc")
          execute :cat, "/tmp/rbenvrc ~/.bashrc > /tmp/bashrc"
          execute :mv, "/tmp/bashrc ~/.bashrc"
          execute %q{export PATH="$HOME/.rbenv/bin:$PATH"}
          execute %q{eval "$(rbenv init -)"}
        end
      end
    end

    task :bootstrap_ubuntu_for_ruby_compile do
      privileged_on release_roles(:all) do |host, user|
        with :debian_frontend => "noninteractive" do
          execute "~#{user}/.rbenv/plugins/rbenv-bootstrap/bin/rbenv-bootstrap-ubuntu-12-04"
        end
      end
    end

    task :compile_ruby do
      ruby_version = fetch(:fiftyfive_rbenv_ruby_version)
      on release_roles(:all) do
        force = ENV["RBENV_FORCE_INSTALL"] || begin
          ! test("rbenv versions | grep -q '#{ruby_version}'")
        end

        if force
          execute "CFLAGS=-O3 rbenv install --force #{ruby_version}"
          execute "rbenv global #{ruby_version}"
          execute "gem install bundler psych --no-document"
          execute "rbenv rehash"
        end
      end
    end

    task :update_rbenv do
      on release_roles(:all) do
        execute "rbenv update"
      end
    end
  end
end
