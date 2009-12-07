require "mechanized_session"
module ActsAsOtherWebsite
  module ActionControllerMethods
    module InstanceMethods
      def on_invalid_credentials
        flash[:error] = "Invalid login credentials"
        redirect_to new_session_path
      end

      def on_invalid_session
        flash[:error] = "Your session is no longer valid"
        redirect_to new_session_path
      end

      def on_unexpected_response(code)
        flash[:error] = "Unexpected response #{code} from remote server"
        redirect_to new_session_path
      end

      def create_mechanized_session
        if session[:mechanized_session]
          @mechanized_session = acts_as_other_website_options[:using].new(:logger => logger, :session_data => session[:mechanized_session])
          logger.debug "Successfully created mechanzied_session from rails session data"
        else
          raise MechanizedSession::InvalidSession
        end        
      end

      def store_mechanized_session
        if @mechanized_session
          session[:mechanized_session] = @mechanized_session.session_data
          logger.debug "Successfully dumped @mechanzied_session data to rails session"
        else
          logger.debug "Not dumping mechanized_session to rails session, @mechanized_session not set"
        end

      end
    end

    def acts_as_other_website(options = {})
      raise "Options to :acts_as_other_website must include :using => SubclassOfMechanizedSession" unless options[:using] && options[:using].is_a?(Class) && options[:using] < MechanizedSession
      include InstanceMethods
      before_filter :create_mechanized_session
      after_filter :store_mechanized_session
      rescue_from MechanizedSession::InvalidAuthentication, :with => :on_invalid_credentials
      rescue_from MechanizedSession::InvalidSession, :with => :on_invalid_session
      rescue_from WWW::Mechanize::ResponseCodeError do |ex|
        if ex.response_code.to_s == "401"
          on_invalid_credentials
        else
          on_unexpected_response(ex.response_code)
        end
      end

      define_method :acts_as_other_website_options do
        options
      end
    end
  end
end

ActionController::Base.extend(ActsAsOtherWebsite::ActionControllerMethods)