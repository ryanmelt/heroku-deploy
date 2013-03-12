module Heroku::Deploy::Task
  class PrepareProductionBranch < Base
    include Heroku::Deploy::Shell

    def before_deploy
      @previous_branch = git "rev-parse --abbrev-ref HEAD"

      # Always fetch first. The repo may have already been created.
      task "Fetching from #{colorize "origin", :cyan}" do
        git "fetch origin"
      end

      task "Switching to #{colorize strategy.branch, :cyan}" do
        branches = git "branch"

        if branches.match /#{strategy.branch}$/
          git "checkout #{strategy.branch}"
          git "reset origin/#{strategy.branch} --hard"
        else
          git "checkout -b #{strategy.branch}"
        end
      end

      task "Merging your current branch #{colorize @previous_branch, :cyan} into #{colorize strategy.branch, :cyan}" do
        git "merge #{strategy.new_commit}"
      end
    end

    def after_deploy
      task "Pushing local #{colorize strategy.branch, :cyan} to #{colorize "origin", :cyan}"
      git "push -u origin #{strategy.branch} -v", :exec => true

      switch_back_to_old_branch
    end

    def rollback_before_deploy
      switch_back_to_old_branch
    end

    private

    def switch_back_to_old_branch
      task "Switching back to #{colorize @previous_branch, :cyan}" do
        git "checkout #{@previous_branch}"
      end
    end
  end
end
