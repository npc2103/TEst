require 'net/http'
require 'uri'
require 'json'
require 'geocoder'
require 'date'


class SearchController < ApplicationController
  API_ENDPOINT = "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/"
  API_KEY = ENV['HOTPEPPER_API_KEY'] # Updated line

  #現在位置を取得・検索距離を指定するページ
  def new
  end

  #ホットペッパー グルメサーチAPIにリクエストを送る
  def create
  end

  #店舗詳細画面の表示
  def show
    shop_id = params[:id]

    uri = URI(API_ENDPOINT)
    api_params = {
      key: API_KEY,
      id: shop_id,
      format: 'json',
    }
    uri.query = URI.encode_www_form(api_params)

    res = Net::HTTP.get_response(uri)
    if res.is_a?(Net::HTTPSuccess)
      result = JSON.parse(res.body)
      if result['results'].nil? || result['results']['error'].present?
        flash[:alert] = '店舗情報の取得に失敗しました。もう一度試してください。'
        redirect_to search_index_path
      else
        @shop = result['results']['shop'][0]
        if @shop.nil?
          flash[:alert] = '店舗情報が見つかりませんでした。'
          redirect_to search_index_path
        end
      end
    else
      flash[:alert] = '店舗情報の取得に失敗しました。もう一度試してください。'
      redirect_to search_index_path
    end
  end

  #検索結果を表示するページ
  def index
    # ログインしているユーザーのIDを取得
    user_id = current_user.id if user_signed_in?

    # ユーザーがブックマークした店舗のIDを取得
    bookmarked_shop_ids = user_signed_in? ? Bookmark.where(user_id: current_user.id).pluck(:shop_id) : []

    @page = params[:page].present? ? params[:page].to_i : 1
    @num = 15
    start = (@page - 1) * @num + 1

    uri = URI(API_ENDPOINT)
    api_params = {
      key: API_KEY,
      lat: params[:latitude],
      lng: params[:longitude],
      range: params[:distance],
      format: 'json',
      count: @num,
      start: start,
      order: 4,
    }
    uri.query = URI.encode_www_form(api_params)

    res = Net::HTTP.get_response(uri)
    if res.is_a?(Net::HTTPSuccess)
      result = JSON.parse(res.body)
      if result['results'].nil?
        flash[:alert] = '検索結果がありません。もう一度試してください。'
        redirect_to new_search_path
      elsif result['results']['error'].present?
        flash[:alert] = '検索に失敗しました。もう一度試してください。'
        redirect_to new_search_path
      else
        @shops = result['results']['shop']
        @total_results = result['results']['results_available'].to_i
        #検索結果の距離を計算
        @shops.each do |shop|
          shop_lat = shop['lat'].to_f
          shop_lng = shop['lng'].to_f
          user_lat = params[:latitude].to_f
          user_lng = params[:longitude].to_f

          distance = Geocoder::Calculations.distance_between([user_lat, user_lng], [shop_lat, shop_lng])
          if distance < 1
            shop['distance'] = (distance * 1000).round(2).to_s + 'm'
          else
            shop['distance'] = distance.round(2).to_s + 'km'
          end

          # 営業時間の判断を行い、shopに'now'を追加　作りかけ
          if shop['open'] =~ /(\w+～\w+): (\d+:\d+)～翌(\d+:\d+)/
            open_days, open_time, close_time = $1, $2, $3
            open_day_start, open_day_end = open_days.split("～").map { |day| days_jp_to_dt[day] }

            if open_day_start <= now.wday && now.wday <= open_day_end
              open_hour, open_minute = open_time.split(":").map(&:to_i)
              close_hour, close_minute = close_time.split(":").map(&:to_i)
              if open_hour <= now.hour && now.hour < 24 || 0 <= now.hour && now.hour < close_hour
                shop['now'] = "〇"
              else
                shop['now'] = "X"
              end
            else
              shop['now'] = "X"
            end
          else
            shop['now'] = "?"
          end
          # ブックマークの確認
          if bookmarked_shop_ids && bookmarked_shop_ids.include?(shop['id'])
            shop['book'] = 1
          else
            shop['book'] = 0
          end
        end
        render :index
      end
    else
      flash[:alert] = '検索に失敗しました。もう一度試してください。'
      redirect_to new_search_path
    end
  end
end
