# coding: utf-8

require 'jiji/test/test_configuration'
require 'jiji/composing/container_factory'

describe Jiji::Security::PasswordResetter do
  before(:example) do
    @data_builder = Jiji::Test::DataBuilder.new

    @container = Jiji::Composing::ContainerFactory.instance.new_container

    @authenticator = @container.lookup(:authenticator)
    @resetter      = @container.lookup(:password_resetter)
    @store         = @container.lookup(:session_store)
    @time_source   = @container.lookup(:time_source)
    @repository    = @container.lookup(:setting_repository)

    @time_source.set Time.utc(2000, 1, 10)
  end

  after(:example) do
    @data_builder.clean
  end

  it 'パスワードを再設定できる' do
    init_setting

    @resetter.send_password_resetting_mail('foo@var.com')

    expect(Mail::TestMailer.deliveries.length).to eq 1

    mail = Mail::TestMailer.deliveries[0]
    expect(mail.subject).to eq 'パスワードの再設定'
    expect(mail.to).to eq ['foo@var.com']
    expect(mail.from).to eq ['jiji@unageanu.net']
    expect(mail.text_part.body.to_s).to match(/トークン\: ([a-zA-Z0-9]+)/)

    reset_token = mail.text_part.body.to_s.scan(/トークン\: ([a-zA-Z0-9]+)/)[0][0]
    expect(@store.valid_token? reset_token, :user).to be false
    expect(@store.valid_token? reset_token, :resetting_password).to be true

    user_token = @authenticator.authenticate('foo')
    expect(@store.valid_token? user_token, :user).to be true

    new_user_token = @resetter.reset_password(reset_token, 'var')

    @authenticator.authenticate('var')
    expect do
      @authenticator.authenticate('foo')
    end.to raise_error(Jiji::Errors::AuthFailedException)

    expect(@store.valid_token? reset_token,    :user).to be false
    expect(@store.valid_token? reset_token,    :resetting_password).to be false
    expect(@store.valid_token? user_token,     :user).to be false
    expect(@store.valid_token? new_user_token, :user).to be true
  end

  it 'メールアドレス未設定の場合、メールは送信できない' do
    expect do
      @resetter.send_password_resetting_mail('foo@var.com')
    end.to raise_error(Jiji::Errors::IllegalStateException)
  end

  it 'メールアドレスが登録されているものと異なる場合、メールは送信できない' do
    init_setting
    expect do
      @resetter.send_password_resetting_mail('foo2@var.com')
    end.to raise_error(ArgumentError)
  end

  context '設定メール送信後' do
    before(:example) do
      init_setting

      @resetter.send_password_resetting_mail('foo@var.com')
      mail = Mail::TestMailer.deliveries[0]
      @token = mail.text_part.body.to_s.scan(/トークン\: ([a-zA-Z0-9]+)/)[0][0]
    end

    it '無効なトークンではパスワードを変更できない' do
      expect do
        @resetter.reset_password('illegal_token', 'var')
      end.to raise_error(ArgumentError)
    end

    it '有効期限が切れたトークンではパスワードを変更できない' do
      @time_source.set Time.utc(2000, 1, 13)
      expect do
        @resetter.reset_password(@token, 'var')
      end.to raise_error(ArgumentError)
    end

    it '使用済みのトークンではパスワードを変更できない' do
      @resetter.reset_password(@token, 'var')
      expect do
        @resetter.reset_password(@token, 'var2')
      end.to raise_error(ArgumentError)
    end

    it 'ログイン時に返されるトークンではパスワードを変更できない' do
      token = @authenticator.authenticate('foo')
      expect do
        @resetter.reset_password(token, 'var')
      end.to raise_error(ArgumentError)
    end
  end

  def init_setting
    @setting       = @repository.security_setting

    @setting.password        = 'foo'
    @setting.mail_address    = 'foo@var.com'
    @setting.expiration_days = 10
    @setting.save
  end
end
