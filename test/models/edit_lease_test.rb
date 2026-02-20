require "test_helper"

class EditLeaseTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:acme_roadmap)
    @lease_token = SecureRandom.hex(32)
  end

  test "acquire creates new lease" do
    lease = EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )
    assert lease.persisted?
    assert lease.held?
    assert_equal @plan.id, lease.plan_id
  end

  test "acquire replaces expired lease" do
    EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )

    lease = EditLease.find_by(plan_id: @plan.id)
    lease.update!(expires_at: 1.minute.ago)

    new_token = SecureRandom.hex(32)
    new_lease = EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:bob_token).id,
      lease_token: new_token
    )
    assert new_lease.persisted?
    assert new_lease.held?
  end

  test "acquire raises conflict when held by another" do
    EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )

    other_token = SecureRandom.hex(32)
    assert_raises(EditLease::Conflict) do
      EditLease.acquire!(
        plan: @plan,
        holder_type: "local_agent",
        holder_id: api_tokens(:bob_token).id,
        lease_token: other_token
      )
    end
  end

  test "acquire with same token renews lease" do
    lease = EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )
    original_expires = lease.expires_at

    travel 1.minute do
      renewed = EditLease.acquire!(
        plan: @plan,
        holder_type: "local_agent",
        holder_id: api_tokens(:alice_token).id,
        lease_token: @lease_token
      )
      assert renewed.expires_at > original_expires
    end
  end

  test "renew updates expiry" do
    lease = EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )

    travel 1.minute do
      lease.renew!(lease_token: @lease_token)
      assert lease.expires_at > Time.current
    end
  end

  test "renew raises conflict with wrong token" do
    lease = EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )

    assert_raises(EditLease::Conflict) do
      lease.renew!(lease_token: "wrong-token")
    end
  end

  test "release destroys lease" do
    lease = EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )

    lease.release!(lease_token: @lease_token)
    assert_nil EditLease.find_by(plan_id: @plan.id)
  end

  test "release raises conflict with wrong token" do
    lease = EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )

    assert_raises(EditLease::Conflict) do
      lease.release!(lease_token: "wrong-token")
    end
  end

  test "held_by? checks token and expiry" do
    lease = EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )

    assert lease.held_by?(lease_token: @lease_token)
    assert_not lease.held_by?(lease_token: "wrong-token")
  end
end
