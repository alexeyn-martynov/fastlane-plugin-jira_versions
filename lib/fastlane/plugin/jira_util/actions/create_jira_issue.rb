module Fastlane
  module Actions
    module SharedValues
      CREATE_JIRA_ISSUE_ISSUE_ID  = :CREATE_JIRA_ISSUE_ISSUE_ID
      CREATE_JIRA_ISSUE_ISSUE_KEY = :CREATE_JIRA_ISSUE_ISSUE_KEY
    end

    class CreateJiraIssueAction < Action
      def self.run(params)
        Actions.verify_gem!('jira-ruby')
        require 'jira-ruby'

        site              = params[:url]
        context_path      = ""
        auth_type         = :basic
        username          = params[:username]
        password          = params[:password]
        project_name      = params[:project_name]
        issue_type_name   = params[:issue_type_name]
        summary           = params[:summary]
        version_name      = params[:version_name]
        description       = params[:description]

        options = {
          username:     username,
          password:     password,
          site:         site,
          context_path: context_path,
          auth_type:    auth_type,
          read_timeout: 120
        }

        client = JIRA::Client.new(options)

        project = client.Project.find(project_name)

        project_id = project.id
        if project_id.nil?
          raise "Project '#{project_name}' not found."
          return false
        end

        issue_type = project.issueTypes.find { |type| type['name'] == issue_type_name }
        if issue_type.nil?
          raise "Issue type '#{issue_type_name}' not found."
          return false
        end

        version = project.versions.find { |version| version.name == version_name }
        if version.nil?
          raise "Version '#{version_name}' not found."
          return false
        end

        issue = client.Issue.build
        issue.save!({
          "fields" => {
            "issuetype" => {"id" => issue_type['id']},
            "project"  => { "id" => project_id },
            "versions" => [{"id" => version.id }],
            "summary"  => summary,
            "description" => description
          }
        })

        issue.fetch
        Actions.lane_context[SharedValues::CREATE_JIRA_ISSUE_ISSUE_ID] = issue.id
        Actions.lane_context[SharedValues::CREATE_JIRA_ISSUE_ISSUE_KEY] = issue.key
        issue.id
      rescue JIRA::HTTPError
        UI.user_error!("Failed to create new JIRA issue: #{$!.response.body}")
        false
      rescue
        UI.user_error!("Failed to create new JIRA issue: #{$!}")
        false
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Creates a new issue in your JIRA project"
      end

      def self.details
        "Use this action to create a new issue in JIRA"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :url,
                                      env_name: "FL_JIRA_UTIL_SITE",
                                      description: "URL for Jira instance",
                                      type: String,
                                      verify_block: proc do |value|
                                        UI.user_error!("No url for Jira given, pass using `url: 'url'`") unless value and !value.empty?
                                      end),
          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FL_JIRA_UTIL_USERNAME",
                                       description: "Username for JIRA instance",
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("No username given, pass using `username: 'jira_user'`") unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :password,
                                       env_name: "FL_JIRA_UTIL_PASSWORD",
                                       description: "Password for Jira",
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("No password given, pass using `password: 'T0PS3CR3T'`") unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :project_name,
                                       env_name: "FL_CREATE_JIRA_ISSUE_PROJECT_NAME",
                                       description: "Project ID for the JIRA project. E.g. the short abbreviation in the JIRA ticket tags",
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("No Project ID given, pass using `project_id: 'PROJID'`") unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :issue_type_name,
                                       env_name: "FL_CREATE_JIRA_ISSUE_ISSUE_TYPE_NAME",
                                       description: "Issue type for the JIRA issue. E.g. Build, Bug, etc",
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("No Issue type name given, pass using `issue_type_name: 'Bug'`") unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :summary,
                                       env_name: "FL_CREATE_JIRA_ISSUE_SUMMARY",
                                       description: "The summary of the issue. E.g. New Issue",
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("No summary given, pass using `summary: 'New Issue'`") unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: "FL_CREATE_JIRA_ISSUE_VERSION_NAME",
                                       description: "The version name of the issue. E.g. Next_Release",
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("No version_name given, pass using `version_name: 'Next_Release'`") unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :description,
                                       env_name: "FL_CREATE_JIRA_ISSUE_DESCRIPTION",
                                       description: "The description text of the issue. E.g. This is important issue",
                                       type: String,
                                       optional: true)
        ]
      end

      def self.output
        [
          ['CREATE_JIRA_ISSUE_ISSUE_ID', 'The id for the newly created JIRA issue'],
          ['CREATE_JIRA_ISSUE_ISSUE_KEY', 'The key (e.g. MYPOJ-123) for the newly created JIRA issue']
        ]
      end

      def self.return_value
        'The id for the newly create JIRA issue'
      end

      def self.authors
        ["https://github.com/SandyChapman", "https://github.com/alexeyn-martynov"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
