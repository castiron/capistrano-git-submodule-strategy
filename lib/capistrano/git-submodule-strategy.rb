require 'capistrano/git'

class Capistrano::Git
  module SubmoduleStrategy
    # do all the things a normal capistrano git session would do
    include Capistrano::Git::DefaultStrategy

    def test
      test! " [ -d #{repo_path}/.git ] "
    end

    def check
      unless test!(:git, :'ls-remote', repo_url)
        context.error "Repo `#{repo_url}` does not exists"
        return false
      end

      if context.capture(:git, :'ls-remote', repo_url).split("\n").select{ |i| i.include?("refs/heads/#{fetch(:branch)}") }.empty?
        context.error "Branch `#{fetch(:branch)}` not found in repo `#{repo_url}`"
        return false
      end

      true
    end

    def clone
      git :clone, '--recursive', '-b', fetch(:branch), repo_url, repo_path
    end

    def update
      git :fetch, '--all'
      git :checkout, '-f', "origin/#{fetch(:branch)}"
      git :submodule, :sync
      git :submodule, :update, '--init', '--recursive'
      git :clean, '-fd'
    end

    # put the working tree in a release-branch,
    # make sure the submodules are up-to-date
    # and copy everything to the release path
    def release
      unless context.test(:test, '-e', release_path) && context.test("ls -A #{release_path} | read linevar")
        context.execute("rm -r #{release_path}/")
        context.execute("cp -r #{repo_path} #{release_path}")
        context.execute("find #{release_path} -name '.git*' | xargs -I {} rm -rfv {}")
      end
    end

    def fetch_revision
      context.capture(:git, "rev-parse --short HEAD").strip
    end
  end
end
