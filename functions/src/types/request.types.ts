export interface CreateServiceRequestInput {
    serviceType: string;
    vehicleDetails: {
    brand: string;
    model: string;
    number: number;
  };
  latitude: number;
  longitude: number;
  dispatchType: "AUTO" | "MANUAL";
}