# frozen_string_literal: true
require 'rails_helper'
require 'json'

RSpec.describe RolesController, type: :controller do
  describe 'Get index' do
    subject { get :index, format: :json }
    let!(:role) { FactoryGirl.create(:role) }

    context 'when not signed in' do
      it { expect(subject).to be_ok }

      it 'roles are shown' do
        json = JSON.parse(subject.body)
        expect(json['data'].length).to eq(1)
      end
    end

    context 'when signed in' do
      let(:guest) { FactoryGirl.create(:user) }
      let(:user) { FactoryGirl.create(:user, :manager) }
      let(:contributor) { FactoryGirl.create(:user, :contributor) }
      let(:admin) { FactoryGirl.create(:user, :admin) }

      it 'guest will see roles' do
        sign_in guest
        json = JSON.parse(subject.body)
        expect(json['data'].length).to eq(1)
      end

      it 'contributor will see draft roles' do
        sign_in contributor
        json = JSON.parse(subject.body)
        expect(json['data'].length).to eq(2)
      end

      it 'manager will see roles' do
        sign_in user
        json = JSON.parse(subject.body)
        expect(json['data'].length).to eq(2)
      end

      it 'admin will see roles' do
        sign_in user
        json = JSON.parse(subject.body)
        expect(json['data'].length).to eq(2)
      end
    end

  end

  describe 'Get show' do
    let(:role) { FactoryGirl.create(:role) }
    subject { get :show, params: { id: role }, format: :json }

    context 'when not signed in' do
      it { expect(subject).to be_ok }

      it 'shows the role' do
        json = JSON.parse(subject.body)
        expect(json['data']['id'].to_i).to eq(role.id)
      end
    end
  end

  describe 'Post create' do
    context 'when not signed in' do
      it 'not allow creating a measure' do
        post :create, format: :json, params: { measure: { title: 'test', description: 'test', target_date: 'today' } }
        expect(response).to be_unauthorized
      end
    end

    context 'when signed in' do
      let(:guest) { FactoryGirl.create(:user) }
      let(:user) { FactoryGirl.create(:user, :manager) }
      let(:contributor) { FactoryGirl.create(:user, :contributor) }
      let(:recommendation) { FactoryGirl.create(:recommendation) }
      let(:category) { FactoryGirl.create(:category) }

      subject do
        post :create,
             format: :json,
             params: {
                 measure: {
                     title: 'test',
                     description: 'test',
                     target_date: 'today'
                 }
             }
        # This is an example creating a new recommendation record in the post
        # post :create,
        #      format: :json,
        #      params: {
        #        measure: {
        #          title: 'test',
        #          description: 'test',
        #          target_date: 'today',
        #          recommendation_measures_attributes: [ { recommendation_attributes: { title: 'test 1', number: 1 } } ]
        #        }
        #      }
      end

      it 'will not allow a guest to create a measure' do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it 'will not allow a contributor to create a measure' do
        sign_in contributor
        expect(subject).to be_forbidden
      end

      it 'will allow a manager to create a measure' do
        sign_in user
        expect(subject).to be_created
      end

      it 'will record what manager created the measure', versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in user
        json = JSON.parse(subject.body)
        expect(json['data']['attributes']['last_modified_user_id'].to_i).to eq user.id
      end

      it 'will return an error if params are incorrect' do
        sign_in user
        post :create, format: :json, params: { measure: { description: 'desc only' } }
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'Put update' do
    let(:measure) { FactoryGirl.create(:measure) }
    subject do
      put :update,
          format: :json,
          params: { id: measure,
                    measure: { title: 'test update', description: 'test update', target_date: 'today update' } }
    end

    context 'when not signed in' do
      it 'not allow updating a measure' do
        expect(subject).to be_unauthorized
      end
    end

    context 'when user signed in' do
      let(:guest) { FactoryGirl.create(:user) }
      let(:user) { FactoryGirl.create(:user, :manager) }
      let(:contributor) { FactoryGirl.create(:user, :contributor) }

      it 'will not allow a guest to update a measure' do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it 'will not allow a contributor to update a measure' do
        sign_in contributor
        expect(subject).to be_forbidden
      end

      it 'will allow a manager to update a measure' do
        sign_in user
        expect(subject).to be_ok
      end

      it 'will record what manager updated the measure', versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in user
        json = JSON.parse(subject.body)
        expect(json['data']['attributes']['last_modified_user_id'].to_i).to eq user.id
      end

      it 'will return an error if params are incorrect' do
        sign_in user
        put :update, format: :json, params: { id: measure, measure: { title: '' } }
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'Delete destroy' do
    let(:measure) { FactoryGirl.create(:measure) }
    subject { delete :destroy, format: :json, params: { id: measure } }

    context 'when not signed in' do
      it 'not allow deleting a measure' do
        expect(subject).to be_unauthorized
      end
    end

    context 'when user signed in' do
      let(:guest) { FactoryGirl.create(:user) }
      let(:user) { FactoryGirl.create(:user, :manager) }
      let(:contributor) { FactoryGirl.create(:user, :contributor) }

      it 'will not allow a guest to delete a measure' do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it 'will not allow a contributor to delete a measure' do
        sign_in contributor
        expect(subject).to be_forbidden
      end

      it 'will allow a manager to delete a measure' do
        sign_in user
        expect(subject).to be_no_content
      end
    end
  end
end