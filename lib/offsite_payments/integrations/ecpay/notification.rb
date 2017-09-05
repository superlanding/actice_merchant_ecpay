require 'net/http'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Ecpay
      class Notification < OffsitePayments::Notification

        def status
          if rtn_code == '1'
            true
          else
            false
          end
        end

        # TODO 使用查詢功能實作 acknowledge
        # Ecpay 沒有遠端驗證功能，
        # 而以 checksum_ok? 代替
        def acknowledge
          checksum_ok?
        end

        def complete?
          case @params['RtnCode']
          when '1' #付款成功
            true
          when '2' # ATM 取號成功
            true
          when '10100073' # CVS 或 BARCODE 取號成功
            true
          when '800' #貨到付款訂單建立成功
            true
          else
            false
          end
        end

        def hash_key=(key)
          @hash_key = key
        end

        def hash_iv=(iv)
          @hash_iv = iv
        end

        def hash_key
          @hash_key || OffsitePayments::Integrations::Ecpay.hash_key
        end

        def hash_iv
          @hash_iv || OffsitePayments::Integrations::Ecpay.hash_iv
        end

        def checksum_ok?
          params_copy = @params.clone

          checksum = params_copy.delete('CheckMacValue')

          # 把 params 轉成 query string 前必須先依照 hash key 做 sort
          # 依照英文字母排序，由 A 到 Z 且大小寫不敏感
          raw_data = params_copy.sort_by{ |k,v| k.downcase }.map do |x, y|
            "#{x}=#{y}"
          end.join('&')

          hash_raw_data = "HashKey=#{hash_key}&#{raw_data}&HashIV=#{hash_iv}"

          url_encode_data = OffsitePayments::Integrations::Ecpay::Helper.url_encode(hash_raw_data)
          url_encode_data.downcase!

          (Digest::MD5.hexdigest(url_encode_data) == checksum.to_s.downcase)
        end

        def rtn_code
          @params['RtnCode']
        end

        def merchant_id
          @params['MerchantID']
        end

        # 廠商交易編號
        def merchant_trade_no
          @params['MerchantTradeNo']
        end
        alias :item_id :merchant_trade_no

        def rtn_msg
          @params['RtnMsg']
        end

        # EcPay 的交易編號
        def trade_no
          @params['TradeNo']
        end
        alias :transaction_id :trade_no

        def trade_amt
          @params['TradeAmt']
        end
        def gross
          ::Money.new(@params['TradeAmt'].to_i * 100, currency)
        end

        def payment_date
          @params['PaymentDate']
        end

        def payment_type
          @params['PaymentType']
        end

        def payment_type_charge_fee
          @params['PaymentTypeChargeFee']
        end

        def trade_date
          @params['TradeDate']
        end

        def simulate_paid
          @params['SimulatePaid']
        end

        def check_mac_value
          @params['CheckMacValue']
        end

        # for ATM
        def bank_code
          @params['BankCode']
        end

        def v_account
          @params['vAccount']
        end

        def expire_date
          @params['ExpireDate']
        end

        # for CreditCard
        def card4no
          @params['card4no']
        end

        # for CVS
        def payment_no
          @params['PaymentNo']
        end

        def currency
          'TWD'
        end

        # for BARCODE
        def barcode1
          @params['Barcode1']
        end

        def barcode2
          @params['Barcode2']
        end

        def barcode3
          @params['Barcode3']
        end
      end
    end
  end
end
