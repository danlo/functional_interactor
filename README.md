# Functional Interactor

Based around https://github.com/collectiveidea/interactor, reimagined to use Kase with composability operators.

## Getting Started

Add Interactor to your Gemfile and `bundle install`.

```ruby
gem "functional_interactor", "~> 0.0.1"
```

This implementation is meant to be used with the [Kase](https://github.com/lasseebert/kase) gem.

## What is an Interactor?

An interactor is a simple, single-purpose object.

Interactors are used to encapsulate your application's
[business logic](http://en.wikipedia.org/wiki/Business_logic). Each interactor
represents one thing that your application *does*.

### Call and Return Protocol

An Interactor must respond to the method `call`, and takes a single object.

An Interactor following this protocol will accept a single object which encapsulates
the state or context. By convention, we use a Hash-like object so that interactors
can be composed into higher-order interactions.

#### Success

When the action succeeds, return
```ruby
[:ok, context]
```

The return value of `context` can be anything, though it is suggested that you
stick with a Hash-like object so that interactors can be chained together.

#### Failure

When the action fails, return an array where the first element is the symbol
`:error`. Examples:

```ruby
[:error, "This failed"]
[:error, :invalid, [{'field' => 'must be present'}]]
[:error, :stripe_error, StripeException.new]
```

You are typically going to use Kase to handle errors:

```ruby
Kase.kase PushUserToElasticSearch.call(user) do
  on(:ok) do |ctx|
    # Do something
  end
  
  on(:error, :network) do |reason|
    NotifyHuman.log "failed to push user ##{user.id} to ElasticSearch"
  end
end
```

### Context

An interactor is given a *context*. The context contains everything the
interactor needs to do its work.

When an interactor does its single purpose, it affects its given context.

Context are assumed to be a Hash like object.

#### Adding to the Context

As an interactor runs it can add information to the context.

```ruby
context[:user] = user
```

### Hooks

This implementation has no hooks.

### An Example Interactor

Your application could use an interactor to authenticate a user.

```ruby
class AuthenticateUser
  include FunctionalInteractor

  def call(context = {})
    user = User.authenticate(context[:email], context[:password])

    return [:error, :not_authenticated] unless user

    context[:user] = user
    context[:token] = user.secret_token

    # Return a new context so we are not modifying the original
    [:ok,  { user: user, token: user.secret_token }]
  end
end
```

To define an interactor, simply create a class that includes the `Interactor`
module and give it a `call` instance method. The interactor can access its
`context` from within `call`.

## Interactors in the Controller

Most of the time, your application will use its interactors from its
controllers. The following controller:

```ruby
class SessionsController < ApplicationController
  def create
    if user = User.authenticate(session_params[:email], session_params[:password])
      session[:user_token] = user.secret_token
      redirect_to user
    else
      flash.now[:message] = "Please try again."
      render :new
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
```

can be refactored to:

```ruby
class SessionsController < ApplicationController
  def create
    Kase.kase AuthenticateUser.call(session_params) do
      on(:ok) do |result|
        session[:user_token] = result[:token]
        redirect_to root_path
      end
      
      on(:error, :not_authenticated) do
        flash.now[:message] = t(result.message)
        render :new
      end
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
```

The `.call` class method simply instantiates a new `AuthenticatedUser` interactor
and passes the context to it. This allows us to create generic interactors 
that can be inlined and composed together. This is discussed in the following section.

## Advanced Usage

### Sequences 

`creativeideas/interactor` has an `Organizer` class. We have a similar code called
`Interactors::Sequence`.

Let's define a second interactor:

```ruby
class NotifyLogin
  include FunctionalInteractor
  
  def call(context = {})
    NotificationsMailer.login(user: context[:user]).deliver
    [:ok, context]
  end
end
```

We can then chain them together like so:

```ruby
interactions = Interactors::Sequence.new
interactions.compose(AuthenticatedUser)
interactions.compose(NotifyLogin)

Kase.kase interactions.call(session_params) do
  on(:ok)    { |context| puts "Yay! Logged in!" }
  on(:error) { |context| puts "Failed to login" }
end
```

Here, the `Interactors::Sequence` object holds a sequence of
interactions. It will call them one by one, starting from the top. If
at any point, it returns something with `[:error, ...]` then the chain
will stop. We can then use `Kase` to handle the error.

### `#compose` and `|`

We do not actually have to create an `Interactors::Sequence` object. The
`#compose` method will create an `Interactors::Sequence` for you. You can
chain them together like so:

```ruby
interactions = AuthenticatedUser.compose(NotifyLogin)

Kase.kase interactions.call(session_params) do
  on(:ok)    { |context| puts "Yay! Logged in!" }
  on(:error) { |context| puts "Failed to login" }
end
```

We also aliased `|` so you can use that instead:

```ruby
interactions = AuthenticatedUser | NotifyLogin

Kase.kase interactions.call(session_params) do
  on(:ok)    { |context| puts "Yay! Logged in!" }
  on(:error) { |context| puts "Failed to login" }
end
```

### Generic Interactors

Sometimes we want to dynamically create an interactor. We can change the
notification interactor to:

```ruby
interactions = AuthenticatedUser \
| Interactors::Anonymous.new do
    NotificationsMailer.login(user: context[:user]).deliver
    [:ok, context]
  end

Kase.kase interactions.call(session_params) do
  on(:ok)    { |context| puts "Yay! Logged in!" }
  on(:error) { |context| puts "Failed to login" }
end
```

There is a helper, `Interactors.new` that can simplify that:

```ruby
interactions = AuthenticatedUser \
| Interactors.new do
    NotificationsMailer.login(user: context[:user]).deliver
    [:ok, context]
  end

Kase.kase interactions.call(session_params) do
  on(:ok)    { |context| puts "Yay! Logged in!" }
  on(:error) { |context| puts "Failed to login" }
end
```

Since we don't care about handling errors, we can `Interactors::Simple` instead:

```ruby
interactions = AuthenticatedUser \
| Interactors::Simple.new { NotificationsMailer.login(user: context[:user]).deliver }

Kase.kase interactions.call(session_params) do
  on(:ok)    { |context| puts "Yay! Logged in!" }
  on(:error) { |context| puts "Failed to login" }
end
```

This might seem like a lot for just a simple mailer. The real value comes from when
there is a long chain of interactions:

```ruby
interactions = AuthenticatedUser \
| FraudDetector
| Interactors::Simple.new { NotificationsMailer.login(user: context[:user]).deliver }
| ActivityLogger.new(:user_logs_in, controller: self)
| Interactors::RPC.new(service: :presence, module: :'Elixir.Presence.RPC', func: :register)

Kase.kase interactions.call(session_params) do
  on(:ok)    { |context| puts "Yay! Logged in!" }
  on(:error) { |context| puts "Failed to login" }
end
```

### Custom Generic Interactors

Generic interactors work because we can override the constructor. In the case of a Rails mailer, 
maybe we want to have a generic mailer:

```ruby
class Interactors::Mailer
  include FunctionalInteractor
  
  def new(mailer:, method:)
    @mailer = mailer
    @method = method
  end
  
  def call(context = {})
    mailer.send(method, context)
    [:ok, context]
  end
end
```

In which case, we can then use that:

```ruby
interactions = AuthenticatedUser \
| Interactors::Mailer.new(mailer: NotificationsMailer, method: :login)

Kase.kase interactions.call(session_params) do
  on(:ok)    { |context| puts "Yay! Logged in!" }
  on(:error) { |context| puts "Failed to login" }
end
```

## Further Discussion

`collectiveideas/interactor` has a great section discussing on when to
use interactors: https://github.com/collectiveidea/interactor#when-to-use-an-interactor
