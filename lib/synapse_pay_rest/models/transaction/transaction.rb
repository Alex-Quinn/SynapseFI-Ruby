module SynapsePayRest
  class Transaction
    attr_reader :node, :amount, :currency, :client_id, :client_name, :created_on,
                :ip, :latlon, :note, :process_on, :supp_id, :webhook, :fees,
                :recent_status, :timeline, :from, :to, :to_type, :to_id,
                :fee_amount, :fee_note, :fee_to_id

    class << self
      # TODO: validate args types
      # TODO: allow either to_node or to_type/to_id
      # TODO: allow node to be entered to fee_to node s alternative
      def create(node:, to_type:, to_id:, amount:, currency:, ip:, **options)
        payload = payload_for_create(node: node, to_type: to_type, to_id: to_id,
          amount: amount, currency: currency, ip: ip, **options)
        node.user.authenticate
        response = node.user.client.trans.create(node_id: node.id, payload: payload)
        create_from_response(node, response)
      end

      def find(node:, id:)
        node.user.authenticate
      end

      def all(node:, page: 1, per_page: 20)
        node.user.authenticate
      end

      private

      # TODO: validate if fee_to node is synapse us
      # TODO: allow multiple fees
      def payload_for_create(node:, to_type:, to_id:, amount:, currency:, ip:,
        **options)
        payload = {
          'to' => {
            'type' => to_type,
            'id' => to_id
          },
          'amount' => {
            'amount' => amount,
            'currency' => currency
          },
          'extra' => {
            'ip' => ip
          }
        }
        # optional payload fields
        payload['extra']['supp_id']    = options[:supp_id] if options[:supp_id]
        payload['extra']['note']       = options[:note] if options[:note]
        payload['extra']['process_on'] = options[:process_in] if options[:process_in]
        other = {}
        other['attachments'] = options[:attachments] if options[:attachments]
        payload['other'] = other if other.any?
        fees = []
        fee = {}
        fee['fee']  = options[:fee_amount] if options[:fee_amount]
        fee['note'] = options[:fee_note] if options[:fee_note]
        fee_to = {}
        fee_to['id'] = options[:fee_to_id] if options[:fee_to_id]
        fee['to'] = fee_to if fee_to.any?
        fees << fee if fee.any?
        payload['fees'] = fees if fees.any?
        payload
      end

      # TODO: convert the nodes and users in response into User/Node objects
      # TODO: rework to handle multiple fees
      def create_from_response(node, response)
        args = {
          node:          node,
          amount:        response['amount']['amount'],
          currency:      response['amount']['currency'],
          client_id:     response['client']['id'],
          client_name:   response['client']['name'],
          created_on:    response['extra']['created_on'],
          ip:            response['extra']['ip'],
          latlon:        response['extra']['latlon'],
          note:          response['extra']['note'],
          process_on:    response['extra']['process_on'],
          supp_id:       response['extra']['supp_id'],
          webhook:       response['extra']['webhook'],
          fees:          response['fees'],
          recent_status: response['recent_status'],
          timeline:      response['timeline'],
          from:          response['from'],
          to:            response['to'],
          to_type:       response['to']['type'],
          to_id:         response['to']['id'],
          fee_amount:    response['fees'].last['fee'],
          fee_note:      response['fees'].last['note'],
          fee_to_id:     response['fees'].last['to']['id'],
        }
        self.new(args)
      end

      def create_multiple_from_response(node, response)
        response.map { |trans_data| create_from_response(node, trans_data) }
      end
    end

    def initialize(**options)
      options.each { |key, value| instance_variable_set("@#{key}", value) }
    end

    def ==(other)
      other.instance_of?(self.class) && !id.nil? &&  id == other.id 
    end
  end
end