module Hpr
  struct CloneRepositoryWorker
    include Sidekiq::Worker

    def perform(url : String, name : String)
      clone_and_push!(url, name)
    end

    private def clone_and_push!(url, name)
      clone_repository(url, name)
      setting_mirror_settings_and_push(url, name)
      update_schedule(url, name)
    end

    private def clone_repository(url, name)
      repository_path = Hpr.config.repository_path
      Dir.cd repository_path

      Hpr.logger.info "cloning #{url} ... #{name}"
      Utils.run_cmd "git clone --mirror #{url} #{name}"
    end

    private def setting_mirror_settings_and_push(url, name)
      Utils.write_mirror_to_git_config(name)

      # Push
      Hpr.logger.info "pushing to mirror ... #{name}"
      Utils.run_cmd "git push mirror"
      Utils.run_cmd "git config hpr.status 'busy'"
      Utils.run_cmd "git config hpr.updated '#{Utils.current_datetime}'"
      Utils.run_cmd "git config hpr.status 'idle'"
    end

    private def update_schedule(url, name)
      schedule_in = Hpr.config.schedule_in
      UpdateRepositoryWorker.async.perform_in(schedule_in, name)

      Dir.cd Utils.repository_path(name)
      Utils.run_cmd "git config hpr.scheduled '#{(schedule_in.from_now).to_s("%F %T %z")}'"
    end
  end
end
